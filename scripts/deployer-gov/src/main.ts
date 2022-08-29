#! /usr/bin/env node
import * as fs from 'fs';
import util from 'util';
import {Actor, HttpAgent} from '@dfinity/agent';
import fetch from 'cross-fetch';
import {AzureKeyVaultSecp256k1Identity} from '@origyn/identity-azure-key-vault'
import {idlFactory} from './ids';
import {CanisterInstallMode} from "@dfinity/agent/lib/cjs";
import {main as upload} from "./ic_assets.js";
import {createActor as createAssetsActor} from './assets';
import {createActor as createLargeCanisterDeployerActor} from './large_canister_deployer';
import {Principal} from "@dfinity/principal";
import * as _ from "lodash";
import {stateModule} from "./utils/utils";
import {stat} from "fs/promises";
import { Command,Option } from 'commander';
import {Buffer} from "buffer";

const DFX_SIZE_CHUNK = 1024000; // one megabyte
const {
    AZURE_CLIENT_ID,
    AZURE_KEY_ID,
    AZURE_VAULT_ID,
    AZURE_TENANT_ID,
} = process.env;

export const readFilePromised = util.promisify(fs.readFile);

const extraIdentitiesPreparation = async (config: Record<string, any>)=>{
    let principalsList: any[];
    let principalInstancesList: any[];
    principalsList =  config.principalsList.split(",");
    principalInstancesList=principalsList.map( (elem)=>  Principal.from(elem));
    return principalInstancesList
};

const getCanisterName = async (config: Record<string, any>) =>
    config.canisterName ? config.canisterName : getCanisterNameByWasm(config.module);

const getCanisterNameByWasm = async (wasmPath: string) => {
    let pathList = wasmPath.split('/');
    let wasmNameWithType = pathList.at(-1);
    let wasmName = wasmNameWithType.split(".");
    return wasmName[0]
};

const installWasm = async (agent, obj) => {
    console.info(`Deploy script: Installing wasm to ${obj.deployingCanisterId} canister`);
    await Actor.install(
        {
            module: obj.wasmModuleFileData,
            mode: CanisterInstallMode[_.capitalize(obj.type)],
        },
        {
            agent,
            canisterId: obj.deployingCanisterId
        });
};

const createCanister = async (agent, principal, config) => {
    console.info("Deploy script: Have unconfigured canister Id. Creating new one canister");
    const walletActor: any = Actor.createActor(
        idlFactory,
        {
            agent,
            canisterId: String(config.walletId)
        }
    );

    console.log("wallet balance", await walletActor.wallet_balance());

    const deployingCanisterData: any = await walletActor.wallet_create_canister(
        {
            cycles: BigInt(config.cycles),
            settings: {
                controller: [principal],
                compute_allocation: [],
                memory_allocation: [],
                freezing_threshold: [],
            }
        },
    );
    if (_.get(deployingCanisterData, 'Ok', false))
        console.info(`Deploy script: Canister created! Canister ID: ${deployingCanisterData.Ok.canister_id}`);
    return await deployingCanisterData.Ok.canister_id;
};

function sleep(ms) {
    return new Promise((resolve) => {
        setTimeout(resolve, ms);
    });
}

async function getOrCreateCanisterId(stateContent: {}, canisterName, agent: HttpAgent, principal: Principal, config) {
    const canisterId = _.get(stateContent, canisterName);
    let deployingCanisterId = canisterId ? canisterId : await createCanister(agent, Principal.from(principal), config);
    await stateModule.storeStateToFile({[canisterName]: deployingCanisterId.toString()});
    console.info(`Deploy script: Cover canister: ${deployingCanisterId}`);
    console.info(`Deploy script: Installing wasm (${config.module}): to canister ${deployingCanisterId}`);
    return deployingCanisterId;
}

async function deploy(config) {
    // Prepare Agent for acccess to DFX
    const identity = await AzureKeyVaultSecp256k1Identity.create({
        clientId: String(AZURE_CLIENT_ID),
        keyId: String(AZURE_KEY_ID),
        vaultId: String(AZURE_VAULT_ID),
        tenantId: String(AZURE_TENANT_ID),
    });

    let agentOptions = {
        identity: identity!,
        host: config.host,
        fetch
    };
    const agent = new HttpAgent(agentOptions);
    const principal = await agent.getPrincipal();

    console.log("Got principal:",principal.toString());

    await agent.fetchRootKey();
    let stateContent = await stateModule.readStateFile();

    let canisterName = await getCanisterName(config);
    console.log(`Preparing ${canisterName} to deploy`);

    let wasmModuleFileData: Buffer;
    if (config.overrideModule) {
        console.log(`Overriding ${config.module} with ${config.overrideModule}`);
        wasmModuleFileData = await readFilePromised(config.overrideModule);
    } else {
        wasmModuleFileData = await readFilePromised(config.module);
    }
    await stat(config.module);

    if (config.canisterType == "asset") {
        let deployingCanisterId = await getOrCreateCanisterId(stateContent, canisterName, agent, principal, config);

        await installWasm(agent, {
            wasmModuleFileData,
            type: config.type,
            deployingCanisterId,
        });
        const assetsActor = createAssetsActor(deployingCanisterId, {agentOptions});
        await upload(assetsActor, config.assetPath);
        return;
    }

    let chunks = [];
    const deployerWasmPath = config.deployerWasmPath;

    const canisterDeployerCanisterName = await getCanisterNameByWasm(config.deployerWasmPath);

    let canisterDeployerCanisterId: any = _.get(stateContent, canisterDeployerCanisterName);
    if (!canisterDeployerCanisterId) {
        canisterDeployerCanisterId = await createCanister(agent, Principal.from(principal), config);
    } else {
        canisterDeployerCanisterId = Principal.fromText(canisterDeployerCanisterId);
    }
    const canisterDeployerWasmFileData = await readFilePromised(deployerWasmPath);
    if (config.redeployDeployerWasm){
        console.info("Deploy script: deploying LCD wasm ...");
        await installWasm(agent, {
            wasmModuleFileData: canisterDeployerWasmFileData,
            type: config.type,
            deployingCanisterId: canisterDeployerCanisterId
        });
        console.info("Deploy script: LCD wasm been upraded");
    }

    await stateModule.storeStateToFile({[canisterDeployerCanisterName]: canisterDeployerCanisterId.toString()});
    const largeCanisterDeployerActor = createLargeCanisterDeployerActor(canisterDeployerCanisterId, {agentOptions});

    let deployingCanisterId = await getOrCreateCanisterId(stateContent, canisterName, agent, canisterDeployerCanisterId, config);

    console.info("Deploy script: start splitting wasm to chunks");
    for (let start = 0; start <= wasmModuleFileData.length; start += DFX_SIZE_CHUNK) {
        const chunk = wasmModuleFileData.slice(start, start + DFX_SIZE_CHUNK);
        chunks.push(chunk);
    }
    console.info("Deploy script: ready");
    console.info("Deploy script: start uploading chunks");

    await largeCanisterDeployerActor.reset();

    for (let start = 0; start < chunks.length; start++) {
        console.log("appending wasm ", start);

        const size = await largeCanisterDeployerActor.appendWasm(Array.from(chunks[start]));

        console.log("appended: size is ", size);
    }
    console.info("Deploy script: ready");
    if (config.type !="upgrade"){
        try{
            console.info("Deploy script: Unsetting exsted wasm");
            await largeCanisterDeployerActor.deleteWasm(Principal.from(deployingCanisterId));
        }catch{
            console.log("Err: Issue with canister wasm uninstalling")
        }
    }
    let actionMethod=null;
    switch (config.type) {
        case "reinstall":
            actionMethod={"reinstall": null};
            break;
        case "install":
            actionMethod={"install": null};
            break;
        default:
            actionMethod={"upgrade": null};
    }

    await largeCanisterDeployerActor.deployWasm(actionMethod, {
        controllers: [[
            await agent.getPrincipal(),
            Principal.from(canisterDeployerCanisterId),
        ]],
        freezing_threshold: [],
        memory_allocation: [],
        compute_allocation: [],
    }, Principal.from(deployingCanisterId), []);
    console.log("Deploy script: updating deployer to parent deployer");
    await sleep(2000);
    await largeCanisterDeployerActor.updateDeployer(Principal.from(deployingCanisterId));
    console.log("Deploy script: reseting Large canister deploy wasm storage");
    if (config.extraMethod) {
        let tmp_args =  Buffer.from(config.extraArgument??"","hex")
        let tmp_arr = tmp_args.toJSON().data
        await largeCanisterDeployerActor.call_raw(Principal.from(deployingCanisterId),config.extraMethod,tmp_arr);
    }
    await largeCanisterDeployerActor.reset();
    console.log("Deploy script: resetted successful");
}

async function main () {
    let program = new Command();

    program
        .addOption(new Option('-d, --deployer-wasm-path [deployerWasmPath]', "Canister Deployer Path"))
        .addOption(new Option('-r, --redeploy-deployer-wasm [deployerState]', "Redeploy deployer wasm file"))
        .addOption(new Option('-w, --wallet-id <id>', "Wallet canister id"))
        .addOption(new Option('-m, --module [path]', "Module that you want to upload to canister"))
        .addOption(new Option('-N, --canister-name [name]', "Name that you want to set to canister"))
        .addOption(new Option('-o, --override-module [path]', "Module that you want to upload instead of original one"))
        .addOption(new Option('-t, --type <mode>',"Upgrade type").choices(["install", "upgrade", "reinstall"]))
        .addOption(new Option('-h, --host [mode]',"Host Addr (without schema)"))
        .addOption(new Option("-C, --cycles <id>", "CanisterId for deploying code"))
        .addOption(new Option("-T, --canister-type <type>", "Type of deploying canister").choices(["wasm", "asset"]))
        .addOption(new Option("-a, --asset-path [path]", "Path to your assets"))
        .addOption(new Option("-p, --principals-list [string]", "Comma separated identities principals list"))
        .addOption(new Option("-e, --extra-argument [path]", "Argument for extra method that will call after deployment"))
        .addOption(new Option("-f, --extra-method [path]", "Extra method that will call after deployment"));

    const opts = await program.parseAsync();
    const options = opts.opts();
    options.host = options.host ?? process.env.ICP_URL;
    console.log(options);
    await deploy(options)
}

main().then(() => {}).catch((e) => {
    console.error(e);
    process.exit(1);
});
