<?php
Header("Content-type: application/javascript");
define('filename', "wcards.txt");

if(file_exists(filename)){
	$fileOfThings = file_get_contents(filename);
	$things = explode("<>", $fileOfThings);

	echo 'responses = new Array();' . "\n";
	foreach($things as $thing){
		if(strlen($thing)){
			echo 'responses.push("' . trim($thing) . '");' . "\n";
		}
	}

	echo 'console.log("Imported " + ' . sizeof($things) . ' + " responses.");' . "\n";
}
else{
	echo 'console.error("Couldn\'t find responses file.");' . "\n";
}