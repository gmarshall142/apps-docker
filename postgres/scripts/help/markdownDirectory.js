#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const _ = require('lodash');
const Markdown = require('markdown-to-html').Markdown;

const _sourcePath = process.argv[2];
const _destPath = process.argv[3];
const _dirName = process.argv[4];

function walk(dir) {
  return new Promise((resolve, reject) => {
    fs.readdir(dir, (error, files) => {
      if (error) {
        return reject(error);
      }
      Promise.all(files.map((file) => {
        return new Promise((resolve, reject) => {
          const filepath = path.join(dir, file);
          fs.stat(filepath, (error, stats) => {
            if (error) {
              return reject(error);
            }
            if (stats.isDirectory()) {
              walk(filepath).then(resolve);
            } else if (stats.isFile()) {
              resolve(filepath);
            }
          });
        });
      }))
        .then((foldersContents) => {
          resolve(foldersContents.reduce((all, folderContents) => all.concat(folderContents), []));
        });
    });
  });
}

const destDir = `${_destPath}/${_dirName}`;
if (!fs.existsSync(destDir)){
  fs.mkdirSync(destDir);
}

walk(`${_sourcePath}/${_dirName}`)
  .then((response) => {
    const opts = {};

    _.forEach(response, (it) => {
      if(it !== `${_sourcePath}/${_dirName}/.DS_Store`) {
        const md = new Markdown();
        const target = it.replace(_sourcePath, _destPath).replace('.md', '.html');
        const dirPath = path.dirname(target);
        if (!fs.existsSync(dirPath)){
          fs.mkdirSync(dirPath);
        }

        md.render(it, opts, function(err) {
          if (err) {
            console.error('>>>' + err);
            process.exit();
          }
          fs.writeFile(target, md.html, (err2) => {
            console.error('>>>' + err2);
            process.exit();
          });
        });
      }
    });
  })
  .catch((error) => {
    console.error(error);
  });

