<?php
Header('Content-type: application/javascript');
error_reporting(E_ALL);
ini_set('display_errors', 1);

?>
blackCards = new Array();
whiteCards = new Array();
cardIDCounter = 0;

// represents a potential response
function WhiteCard(text){
    this.text = text;
    this.ID = cardIDCounter++;

    this.getText = function(){
        return this.text;
    };

    this.getID = function() {
        return this.ID;
    };

    this.toString = function(){
        var string = '';
        string += this.text;

        if(DEBUG){
            string += ' [ID ' + this.ID + ']';
        }

        return string;
    }

}
// represents a prompt
function BlackCard(text, numOfBlanks){
    this.text = text;
    this.ID = cardIDCounter++;
    this.numOfBlanks = numOfBlanks;

    this.getText = function(){
        return this.text;
    };

    this.getID = function(){
        return this.ID;
    };

    this.getNumOfBlanks = function(){
	    return this.numOfBlanks;
	}

    this.toString = function(){
        var string = '';
        string += this.text;

        if(DEBUG){
            string += ' [ID ' + this.ID + ' numOfBlanks ' + this.numOfBlanks + ']';
        }

        return string;
    }

}

<?php
$promptFilenames = array();
$promptFilenames[] = 'http://www.cardsagainsthumanity.com/bcards2.txt';
$promptFilenames[] = 'http://www.cardsagainsthumanity.com/bcards1.txt';
$promptFilenames[] = 'http://www.cardsagainsthumanity.com/bcards.txt';

$responseFilenames = array();
$responseFilenames[] = 'http://www.cardsagainsthumanity.com/wcards.txt';

// populate strings for white cards
foreach($promptFilenames as $url){
	$source = file_get_contents($url);

	// remove junk
	$source = str_replace('cards=', '', $source);
	$source = str_replace('Â®', '&reg;', $source);
	$source = str_replace('This is the way the world ends \ This is the way the world ends \ ', "This is the way the world ends \\n\\n", $source);
	$source = str_replace('"', '&quot;', $source);

	$lines = explode('<>', $source);

	foreach($lines as $prompt){
		// Construct BlackCard object in js
		$numOfBlanks = 0;
		$underscoreMatches = array();
		preg_match_all("/_+/", $prompt, $underscoreMatches);
		$numOfBlanks = sizeof($underscoreMatches[0]);
        if($numOfBlanks == 0){
            $numOfBlanks = 1;
        }
		echo "blackCards.push(new BlackCard(\"$prompt\", '$numOfBlanks'));\n";
	}
}

// populate strings for black cards
foreach($responseFilenames as $url){
	$source = file_get_contents($url);

	// remove junk
	$source = str_replace('™', '&trade;', $source);
	$source = str_replace('"', '&quot;', $source);

	$lines = explode('<>', $source);

	foreach ($lines as $prompt){
		// Construct WhiteCard object in js
		echo "whiteCards.push(new WhiteCard(\"$prompt\"));\n";
	}
}
