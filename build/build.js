// Note: This is a work in progress
// More items need to be added to this build script
var
  fs = require('fs'),
  path = require('path'),
  archiver = require('archiver') // For ziping www
;

// Parameters
if (process.argv.length <= 2){
  console.log('Missing version number parameter');
  process.exit(1);
}

var params = {
  version : process.argv[2]
}

console.log('Parameters: ', params);



// Config
var
  files = {
    apexPluginJson : {
      path : path.resolve(__dirname,'../apexplugin.json'),
      contents : '',
      json : {}
    },
    wwwZip : {
      path : path.resolve(__dirname,'../source/www.zip'),
      wwwPath : path.resolve(__dirname,'../source/www')
    },
    apexPlugin : {
      path : path.resolve(__dirname,'../item_type_plugin_com_clarifit_fromtodatepicker.sql'),
      contents : ''
    }
  }
;


console.log('*** Changing Version Numbers ***');

// apexpluginjson
files.apexPluginJson.contents = fs.readFileSync(files.apexPluginJson.path, 'utf8');
files.apexPluginJson.json = JSON.parse(files.apexPluginJson.contents);
// Change values
files.apexPluginJson.json.version = params.version;
// Write back
fs.writeFile(files.apexPluginJson.path, JSON.stringify(files.apexPluginJson.json, null, 2), 'utf8');

// Plugin Export
files.apexPlugin.contents = fs.readFileSync(files.apexPlugin.path, 'utf8');
files.apexPlugin.contents = files.apexPlugin.contents.replace(/p_version_identifier=>'.*'/g, "p_version_identifier=>'" + params.version + "'");
//Impage Prefix (reset to null)
files.apexPlugin.contents = files.apexPlugin.contents.replace(/p_image_prefix=>'.*'/g, "p_image_prefix=>''");
fs.writeFile(files.apexPlugin.path,files.apexPlugin.contents);



console.log('*** Creating www.zip ***');
var
  archive = archiver.create('zip', {}),
  output = fs.createWriteStream(files.wwwZip.path)
;

output.on('close', function() {
  console.log('www.zip: ' + archive.pointer() + ' bytes');
});

archive.pipe(output);
archive.bulk(
  [
    {src: '**', expand: true, cwd: files.wwwZip.wwwPath + '/'}
  ],
  {
    dot: false
  }
).finalize();
console.log(files.wwwZip.wwwPath);
