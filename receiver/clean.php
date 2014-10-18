<?php
if($argc != 3){
	die("Usage: clean.php [filename to be cleaned] [destination file]\n\n");
}

// Clean up file
$file = file_get_contents($argv[1]);
$fileParts = explode("\n", $file);
$newFile = '';

foreach($fileParts as &$line){
	$line = strtolower(trim($line));
	
	// Make sure it starts with 'things'
	$byWord = explode(" ", $line);
	if($byWord[0] != "things"){
		$line = "things " . $line;
	}

	// Capitalize the first word of every sentence
	$bySentence = explode(".", $line);
	$line = '';
	foreach($bySentence as &$sentence){
		$sentence = ucfirst($sentence);
		$line .= $sentence . ". ";
	}

	$line = trim($line);

	// Make sure the last character is a '.'
	if(substr($line, -1, 1) != "." && substr($line, -1, 1) != "!" && substr($line, -1, 1) != "?"){
		$line .= ".";
	}

	$newFile .= $line . "\n";
}

file_put_contents($argv[2], $newFile);
