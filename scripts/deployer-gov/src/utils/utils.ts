import {access, open, readFile, writeFile} from 'fs/promises';

export const stateFileName = "state.json";
export const stateModule = {

    createStateFile: async (filename = stateFileName) => {
        try {
            await access(filename);
            console.info(`State file ${filename} already existed.`);
        } catch (e) {
            await open(filename, "w");
            console.info(`Creating state file ${filename}`);
        }
    },
    storeStateToFile: async (newState) => {
        try {
            let existedStateContent = await stateModule.readStateFile();
            let res = Object.assign(existedStateContent, newState);
            await stateModule.writeStateToFile(res)
        } catch (e) {
            throw e;
        }
    },
    readStateFile: async (filename = stateFileName) => {
        let content = {};
        await stateModule.createStateFile(filename);
        let rawContentFile = await readFile(filename, {encoding: "utf-8"});
        if (rawContentFile.length)
            content = JSON.parse(rawContentFile);
        return content
    },
    writeStateToFile: async (data, filename = stateFileName) => {
        await writeFile(filename, JSON.stringify(data));
        console.log(`Saved state to file ${filename}`)
    }
};
