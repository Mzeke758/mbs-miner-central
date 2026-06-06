const fs = require('fs');
const path = require('path');
const https = require('https');
const http = require('http');

const indexPath = path.join(process.cwd(),'index.html');
const previewHost = 'https://id-preview--39ea59ef-38bd-4a92-be4d-65603fe4c4ff.lovable.app';
const html = fs.readFileSync(indexPath,'utf8');
const regex = /(?:src|href)=['"](\/[^'"\s>]+)['"]/g;
let m;
const urls = new Set();
while ((m = regex.exec(html)) !== null) urls.add(m[1]);
console.log('Found', urls.size, 'unique asset paths');

function download(fullUrl, localPath){
  return new Promise((resolve,reject)=>{
    const dir = path.dirname(localPath);
    fs.mkdirSync(dir,{recursive:true});
    const file = fs.createWriteStream(localPath);
    const lib = fullUrl.startsWith('https')? https : http;
    lib.get(fullUrl, (res) => {
      if (res.statusCode >=200 && res.statusCode <300) {
        res.pipe(file);
        file.on('finish', ()=>{ file.close(); resolve(); });
      } else if (res.statusCode >=300 && res.statusCode <400 && res.headers.location) {
        download(res.headers.location, localPath).then(resolve).catch(reject);
      } else {
        file.close(); fs.unlink(localPath,()=>{});
        reject(new Error('HTTP ' + res.statusCode + ' for ' + fullUrl));
      }
    }).on('error', (err)=>{ file.close(); fs.unlink(localPath,()=>{}); reject(err); });
  });
}

(async ()=>{
  for (const p of urls){
    if (p.startsWith('data:')) continue;
    const full = previewHost + p;
    const local = path.join(process.cwd(), p.replace(/^\//,''));
    try{
      console.log('Downloading', full);
      await download(full, local);
    } catch(e){
      console.error('Failed', full, e.message);
    }
  }
  console.log('Done');
})();
