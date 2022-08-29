import * as fs from "fs";
import * as path from "path";
import util from "util";
import * as _ from "lodash";

let assets;

const chunkSize = 700000;
const readDirPromised = util.promisify(fs.readdir);
const statPromised = util.promisify(fs.stat);
const readFilePromised = util.promisify(fs.readFile);
const mimeTypesArr = {
    ".js":{mime:"text/javascript; charset=UTF-8",gzip:false},
    ".js.gz":{mime:"text/javascript; charset=UTF-8",gzip:true},
    ".js.map.gz":{mime:"application/json; charset=UTF-8",gzip:true},
    ".html":{mime:"text/html; charset=UTF-8",gzip:false},
    ".html.gz":{mime:"text/html; charset=UTF-8",gzip:true},
    ".png":{mime:"image/png; charset=UTF-8",gzip:false},
    ".png.gz":{mime:"image/png; charset=UTF-8",gzip:true},
    ".jpeg":{mime:"image/jpeg; charset=UTF-8",gzip:false},
    ".jpg":{mime:"image/jpeg; charset=UTF-8",gzip:false},
    ".jpeg.gz":{mime:"image/jpeg; charset=UTF-8",gzip:true},
    ".jpg.gz":{mime:"image/jpeg; charset=UTF-8",gzip:true},
    ".ico":{mime:"image/x-icon; charset=UTF-8",gzip:false},
    ".svg":{mime:"image/svg+xml; charset=UTF-8",gzip:false},
    ".txt":{mime:"text/plain; charset=UTF-8",gzip:false},
    ".css":{mime:"text/css; charset=UTF-8",gzip:false},
    ".css.map.gz":{mime:"application/json; charset=UTF-8",gzip:true},
    ".css.gz":{mime:"text/css; charset=UTF-8",gzip:true},
};


const walkDir = async (dir)=> {
    let results = [];
        let res = await readDirPromised(dir);
        if (!res.length) return results;
        for(let file of res) {
            const filePath = path.resolve(dir, file);
            let stat = await statPromised(filePath);
            if (stat && stat.isDirectory()){
                let response = await walkDir(filePath);
                results=results.concat(response);
            }
            else {
                results.push(filePath);
            }
        }
    return results
};


const uploadChunk = async ({ batch_id, chunk }) => {
    return assets.create_chunk({
        batch_id: batch_id,
        content: [...chunk]
    })
};

const upload = async (file,dir) => {

    if (!file) {
        await console.error('No file selected');
        return;
    }

    console.log(`Uploading ${file}...`);

    let mimeType = "";
    let gzipped = "";

    let splittedFileName =  file.split("/");
    let filename = splittedFileName[splittedFileName.length - 1];
    let rootDirArr =  dir.split("/");
    let rootDir =rootDirArr[rootDirArr.length - 1];
    let rootDirPosition = _.indexOf(splittedFileName,rootDir);
    // Just for take care after root dirname files (from dist)
    let preparedFileNameArr = _.slice(splittedFileName,rootDirPosition+1);
    let preparedFileName = _.join(preparedFileNameArr,"/");

     _.map(mimeTypesArr,(val,key)=>{
            if (_.endsWith(filename,key)) {
                mimeType=val.mime;
                gzipped=val.gzip?"gzip":"identity"
            }
        });
    let fileContent=await readFilePromised(file);

    if (gzipped){
        preparedFileName = _.replace(preparedFileName,".gz","")
    }

    if (file.length > 0) {
        await assets.store({
            content_encoding: gzipped,
            key: "/"+preparedFileName,
            content_type: mimeType,
            sha256: [],
            content: [...fileContent]
        });
    }
    console.log(`uploaded ${preparedFileName} (${fileContent.length} bytes)`);
};

const main = async (actor, dir) => {
    assets = actor;
    const res = await walkDir(dir);
    await upload(res[0],dir);

    res.map(async (res)=>{
        await upload(res,dir)
    })
};

export { main }
