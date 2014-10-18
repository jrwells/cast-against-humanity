// Error Constants

INVALID_TYPE              = -1;
SUBMITTED_WRONG_NUM_CARDS =  1;
CHOSE_INVALID_PLAYER      =  2;
JUDGED_TOO_EARLY          =  3;
SENT_BLANK_NAME           =  4;
ROUND_IN_PROGRESS         =  5;
NOT_ENOUGH_PLAYERS        =  6;

// Other Constants
NORMAL_HAND_SIZE = 7;

// When debug mode is on, all Response and Player objects are printed with
// all human-useful member variables. Not great for competitive play.
DEBUG = false;

// Used to exit the game after inactivity
idleTime = 0;
IDLE_MAX = 15;

function Player(name, channel) {
    this.name     = name;
    this.ID       = -1;
    this.channel  = channel;
    this.score    = 0;
    this.hand     = new Array();
    this.trophies = new Array();

    this.getScore = function() {
        return this.score;
    };

    this.incrementScore = function() {
        this.score++;
    };

    this.getID = function() {
        return this.ID;
    };

    this.clientSafeVersion = function(){
        var thisObj        = new Object();
        thisObj.name       = this.name;
        thisObj.ID         = this.ID;
        thisObj.score      = this.score;
        thisObj.hand       = this.hand;
        return thisObj;
    }

    this.toString = function(noImage){
        var string = '';
        string += this.name;

        if(DEBUG){
            string += ' [ID ' + this.ID + ', score ' + this.score + ']';
        }

        return string;
    }
}

function Response(cards, submitter){
    //an array of cardIDs
    this.cards = cards;
    this.submitter = submitter;
}

function Game() {
    this.players       = new Array();
    this.playerQueue   = new Array();
    this.responseDeck  = whiteCards;
    this.promptDeck    = blackCards;

    // A dictionary from cardIDs to cards ({cardID : card}) to keep track
    // of all cards dealt
    this.dealtResponses = new Object();

    // Shuffle both decks
    this.responseDeck = shuffle(this.responseDeck);
    this.promptDeck = shuffle(this.promptDeck);

    // An array of response IDs specific to the round
    this.currentResponses = new Array(); //reset this after each new round
    this.judge = 0;
    this.testBool = true;
    this.isBetweenRounds = true;

    // The current prompt card
    this.currentCard = new BlackCard('NULL', 0);

    this.addPlayer = function(player){
        var i = 0;
        while(typeof this.players[i] != 'undefined'){
            i++;
        }
        player.ID = i;
        this.players[i] = player;
        player.channel.send({ type : 'didJoin', number : player.ID });

        updatePlayerList();
    }

    this.queuePlayer = function(player){
        this.playerQueue.push(player);
        player.channel.send({ type: 'didQueue' });
        updatePlayerList();
    }

    this.deQueuePlayerByChannel = function(channel){
        for(var i = 0; i < this.playerQueue.length; i++){
            if(this.playerQueue[i].channel == channel){
                this.playerQueue.splice(i, 1);
                updatePlayerList();
                return;
            }
        }

        console.error('Failed to dequeue player by channel');
    }

    this.deletePlayer = function(id){
        console.log("Deleted player " + this.players[id].toString());
        this.players.splice(id, 1);
        updatePlayerList();
    }

    this.sendGameSync = function(){
        // Update all clients' user list and scores
        var playerList = new Object();
        for(var i = 0; i < this.players.length; i++){
            //this.checkHandSize(players[i]);
            playerList[i] = this.players[i].clientSafeVersion();
        }
        for(var i = 0; i < this.players.length; i++){
            if (!this.judge){
                this.judge = 0;
            }

            this.players[i].channel.send({ type : 'gameSync', player : playerList[i], judge : this.players[this.judge].ID });
        }
    }

    this.advanceJudge = function(){
        this.judge++;
        this.judge = this.judge % this.players.length;
    }

    this.checkHandSize = function(playerID){
        if (this.currentCard.numOfBlanks == 1){
            if (this.players[i].hand.length > 7){
                this.players[i].hand.pop();
            }
        }
        else{
            if (this.players[i].hand.length > 8){
                this.players[i].hand.pop();
            }
        }
            
    }
}

function getPlayerIndexByChannel(channel){
    // First check players
    for(var i = 0; i < game.players.length; i++){
        if(game.players[i].channel == channel){
            return i;
        }
    }

    // Now check queue
    for(var i = 0; i < game.playerQueue.length; i++){
        if(game.playerQueue[i].channel == channel){
            return i;
        }
    }

    console.error('Failed to find player index by channel');
    return -1;
}

// Update (reset) the list of players on screen
function updatePlayerList(){

    // Only update the dispay if not currently playing
    if (game.isBetweenRounds){
        // Reset the card classes
        $('.won').removeClass('card response won').addClass('card response unrevealed');
        $('.lost').removeClass('card response lost').addClass('card response unrevealed');
        $( ".response > p" ).html('?');
        $('.secondAnswer').hide();

        for (var i = 0; i < game.players.length; i++){
            $(".response p:contains('?'):not(:hidden):first").parent().removeClass('card response unrevealed').addClass('card response won');
            $(".response p:contains('?'):not(:hidden):first").html(game.players[i].name + ' is playing');   
        }
        for (var i = 0; i < game.playerQueue.length; i++){
            $(".response p:contains('?'):not(:hidden):first").parent().removeClass('card response unrevealed').addClass('card response won');
            $(".response p:contains('?'):not(:hidden):first").html(game.playerQueue[i].name + ' is <em> queued </em>');   
        }


        $('.promptText').html('Game Lobby');

        $('.judgeOrWinner').html('<em> Waiting to start the next round</em>');
    }
}

// For testing only
function testUpdatePlayerList(currentPlayers, queuedPlayers){
    $( ".response > p" ).html('?');
    $('.secondAnswer').hide();
    if (!currentPlayers){
        currentPlayers = ['Ted', 'Ned', 'Fred'];
    }
    if (!queuedPlayers){
        queuedPlayers = ['Ken', 'Ben'];
    }

    for (var i = 0; i < currentPlayers.length; i++){
        $(".response p:contains('?'):not(:hidden):first").parent().removeClass('card response unrevealed').addClass('card response won');
        $(".response p:contains('?'):not(:hidden):first").html(currentPlayers[i] + ' is playing');   
    }
    for (var i = 0; i < queuedPlayers.length; i++){
        console.log("in this loop");
        $(".response p:contains('?'):not(:hidden):first").parent().removeClass('card response unrevealed').addClass('card response won');
        $(".response p:contains('?'):not(:hidden):first").html(queuedPlayers[i] + ' is <em> queued </em>');   
    }

    $('.promptText').html('Game Lobby');

    $('.judgeOrWinner').html('<em> Waiting to start the next round</em>');
}

function joinPlayer(channel, response){
    if(response.name === ""){
        channel.send({ 'type' : 'response', 'code': SENT_BLANK_NAME });
        console.warn('Received blank name');
        return;
    }
    var newPlayer = new Player(response.name, channel);
    game.queuePlayer(newPlayer);
}

function leavePlayer(channel){
    // If this player is queued, just dequeue them
    for(var i = 0; i < game.playerQueue.length; i++){
        if(game.playerQueue[i].channel == channel){
            game.deQueuePlayerByChannel(channel);
            updatePlayerList();
            return;
        }
    }

    // Is this the last player?
    if(game.players.length == 1){
        newGrind();
        betweenRounds();
    }

    playerID = getPlayerIndexByChannel(channel);
    // If they're currently judge, new round
    if(game.judge == playerID){
        if(!game.isBetweenRounds){
            game.advanceJudge();
        }
    }

    game.deletePlayer(playerID);
    game.sendGameSync();

    return;
}

function roundScreen(){
    //$( ".response > p" ).html('?');
    $('.firstAnswer').html('?');
    $('.secondAnswer').html('?');

    //reset the card classes
    $('.won').removeClass('card response won').addClass('card response unrevealed');
    $('.lost').removeClass('card response lost').addClass('card response unrevealed');

    $('.promptText').html(game.currentCard.text);

    $('.judgeOrWinner').html('<em>' + game.players[game.judge].name + '</em> is judging</p>');
}

// For testing only
function testRoundScreen(){
    $( ".response > p" ).html('?');
    if (game.currentCard.numOfBlanks < 2){
        $('.secondAnswer').hide();
    }
    else{
        $('.secondAnswer').show();
    }
   
    $('.won').removeClass('card response won').addClass('card response unrevealed');
    $('.lost').removeClass('card response lost').addClass('card response unrevealed');

    $('.promptText').html(game.currentCard.text);

    $('.judgeOrWinner').html(' <em>poop</em> is judging');

}

function startNextRound(channel){
    // Only can start if we're in between rounds
    if(!game.isBetweenRounds){
        console.warn('Tried to start a new round during a round.');
        channel.send({ 'type' : 'response', 'code': ROUND_IN_PROGRESS });
        return;
    }

    // Only can start if we have > 2 players
    if((game.players.length + game.playerQueue.length) < 3){
        console.warn("Tried to start new round with not enough players.");
        channel.send({ 'type' : 'response', 'code': NOT_ENOUGH_PLAYERS });

        return;
    }

    newGrind();

    game.isBetweenRounds = false;

    // Show next black card
    roundScreen();

    console.debug('starting next round');
    console.debug(game);

    // Let everyone know the round has started
    for(var i = 0; i < game.players.length; i++){
        game.players[i].channel.send({ 'type' : 'roundStarted', 'prompt': game.currentCard.text, 'numOfBlanks': game.currentCard.numOfBlanks});
    }
}

function betweenRounds(){
    // Notify everyone that we're in between rounds
    for(var i = 0; i < game.players.length; i++){
        game.players[i].channel.send({ 'type' : 'roundEnded' });
    }

    game.isBetweenRounds = true;
}

// Deal one card to one player
function onePlayerDeal(playerID, card){
    console.debug('onePlayerDeal: playerID = ' + playerID +'; card = ' + card.text);
    
        if (game.currentCard.numOfBlanks == 1 ){
            if (game.players[playerID].hand.length < 7){
                game.players[playerID].hand.push(card);
            }
        }
        else{
            if (game.players[playerID].hand.length < 8){
                game.players[playerID].hand.push(card);
            }
        }


        //game.players[playerID].hand.pop();

    console.debug("game.players[playerID].hand: " + game.players[playerID].hand);
    game.sendGameSync();
}

// Deal numOfCards cards to everyone
function globalDeal(numOfCards){
    for(var i = 0; i < numOfCards; i++){
        for(var j = 0; j < game.players.length; j++){
            //if (game.players[j].ID == game.judge){
            //    console.log("globalDeal:  don't deal to last judge: " + game.judge);
            //    continue;
            //}
            if (game.players[j].ID != game.judge){
                // Draw a card
                var thisCard = game.responseDeck.pop();
                onePlayerDeal(game.players[j].ID, thisCard);
                // Store the card in dealtResponses
                game.dealtResponses[thisCard.ID] = thisCard;
            }
        }
    }
}

// Prepare for next question
// Called by startNextRound(channel)
function newGrind(){
    console.debug('processing player queue');
    // Add players who are queued
    for(var i = 0; i < game.playerQueue.length; i++){
        console.debug('enqueuing player ' + i);

        game.addPlayer(game.playerQueue[i], true);

         // Deal them an initial hand of 6
        for(var j = 0; j < NORMAL_HAND_SIZE; j++){
            // choose card and deal
            var thisCard = game.responseDeck.pop();
            console.debug('thisCard: ' + thisCard.text + ' id: ' + thisCard.ID);
            onePlayerDeal(game.playerQueue[i].ID, thisCard);
            console.debug("putting into dealtResponses");
            game.dealtResponses[thisCard.ID] = thisCard;

        }

        console.debug('enqueued player ' + i);
    }

    console.debug('player queue processed');

    // Clear player queue
    game.playerQueue = [];

    // Clear responses
    game.currentResponses = [];

    // Choose next prompt
    game.currentCard = game.promptDeck.pop();
    //while (game.currentCard.numOfBlanks != 2){
    //    game.currentCard = game.promptDeck.pop();
    //}

      // Deal needed number of new cards all around
    if(game.currentCard.numOfBlanks < 2){
        globalDeal(1);
    }
    else{
        globalDeal(game.currentCard.numOfBlanks);
    }

    // Choose next judge
    game.advanceJudge();

    // Reset the number of cards that have been read
    game.numReadCards = 0;

  

    updatePlayerList();
    game.sendGameSync();

}

function updatePlayer(channel, info){
    var playerID = getPlayerIndexByChannel(channel);

    // Find out if we're queued
    var isQueued = false;
    for(var i = 0; i < game.playerQueue.length; i++){
        if(game.playerQueue[i].channel == channel){
            isQueued = true;
        }
    }

    console.log("changing player name. isQueued: " + isQueued);
    if(isQueued){
        game.playerQueue[playerID].name = info.name;
    }
    else{
        game.players[playerID].name = info.name;
    }

    updatePlayerList();
}

function playSubmission(channel, response){

    // CurrentResponses is an array of responses (with each response having both an array of cards and a submitter)
    // The response parameter though just contains an array of cardIDs (not cards)

    // Check that the client submitted the correct number of cards


    
    if (response.cardIDs.length > 2){
        response.cardIDs = $.parseJSON(response.cardIDs);
    }


  



    if (game.currentCard.numOfBlanks != response.cardIDs.length){
        console.error("Player tried to submit incorrect num of cards"); 
        channel.send({ 'type' : 'response', 'code': SUBMITTED_WRONG_NUM_CARDS });
        return;
    }

    // Has this player already submitted cardIDs? update them

    for(var i = 0; i < game.currentResponses.length; i++){
       
        if(game.currentResponses[i].submitter == game.players[getPlayerIndexByChannel(channel)].ID){
            for (var j = 0; j < game.currentResponses[i].cards.length ; j++){
                game.currentResponses[i].cards[j] = game.dealtResponses[response.cardIDs[j]];
            }
            return;
        }
    }

    // Or if they haven't submitted+    
    var submittedCards =[];
    // Get the respective cards for the submitted cardIDs
    for (var i = 0; i < response.cardIDs.length ; i++){
            // game.dealtResponses is an associative array from cardID to card object
            submittedCards.push(game.dealtResponses[response.cardIDs[i]]);
    }
    game.currentResponses.push(new Response(submittedCards, getPlayerIndexByChannel(channel)));
    
    // Done submitting?
    if(game.currentResponses.length == (game.players.length - 1)){
        // Start the judging
        for(var i = 0; i < game.players.length; i++){
            game.players[i].channel.send({ 'type' : 'judging' });
        }
        // Send the judge the currentResponses
        sendJudgeSubmissions();

        // Call the following only when receieved judge's response
        // Remove submitted cards from players' hands
       
        // No matching currentresponses for judge
        for(var i = 0; i < game.currentResponses.length; i++){
           
            if (game.currentResponses[i].submitter != game.judge){
                for(var j = 0; j < game.currentResponses[i].cards.length; j++){
                
                    var targetIndex = game.players[game.currentResponses[i].submitter].hand.indexOf(game.currentResponses[i].cards[j]);
                    game.players[game.currentResponses[i].submitter].hand.splice(targetIndex, 1);
                }
            }
        }
    }
}

// Send the judge all current responses
function sendJudgeSubmissions(){
    game.players[game.judge].channel.send({'type' : 'judgeSubmissions', 'responses' : game.currentResponses});
}

// Handle the judge's response of choosing the winning player
function submissionsJudged(channel, response){
    // Check that all cards have been revealed before allowing judging
    if (game.numReadCards != ((game.players.length-1) * game.currentCard.numOfBlanks)){
        console.error("Judge tried to judge before all cards were read");
        channel.send({ 'type' : 'response', 'code': JUDGED_TOO_EARLY });
        return;
    }

    // Find the response that corresponds to the winningPlayerID
    for (var i = 0; i < game.currentResponses.length; i++){
        if (game.currentResponses[i].submitter == response.winningPlayerID){
            var winningCards = game.currentResponses[i].cards;
            break;
        }
    }

   
    if (!winningCards || game.currentResponses[i].submitter == game.judge){
        console.error("Judge tried to submit an invalid winningPlayerID");
        channel.send({ 'type' : 'response', 'code': CHOSE_INVALID_PLAYER });
        return;
    }

    // Update the winning player's trophies
    for (var i = 0; i < winningCards.length; i++){
        game.players[response.winningPlayerID].trophies.push(winningCards[i]);
    }

    // And score
    game.players[response.winningPlayerID].incrementScore();

    // Visually indicate the winning card(s) by fading the other cards
    for (var i = 0; i < game.currentResponses.length; i++){
        $('.response').removeClass('card response').addClass('card response lost');  
    }

    for (var i = 0; i < winningCards.length; i++){
        // And reset the winning player's card(s) to not be faded
        $('.response p:contains(' + winningCards[i] + ')').parent().removeClass('card response lost').addClass('card response won');
        break;
    }
    

    // And visually indicate the winning player
    $('.judgeOrWinner').html('<em>' + game.players[response.winningPlayerID] + '</em> wins this round!');
    
    // End the round
    betweenRounds();

}

// For testing only
function testSubmissionsJudged(text, numResponses){
    console.log('called testSubmissionsJudged:') //visually indicate the winning card(s) by fading the other cards
    
    for (var i = 0; i < numResponses; i++){
        $('.response').removeClass('card response unrevealed').addClass('card response lost');
    }

    $('.response p:contains(' + text + ')').parent().removeClass('card response lost').addClass('card response won');

    $('.judgeOrWinner').html(' <em>poopy</em> wins this round');
}

// The judge will reveal the currentResponses one-by-one
// @param response: int[] cardIDs
function revealCard(channel, response){

    

     if (response.cardIDs.length > 2){
        response.cardIDs = $.parseJSON(response.cardIDs);
    }
   
   

    
     if (response.cardIDs.length < 2){
            $(".firstAnswer:contains('?'):first").parent().removeClass('card response unrevealed').addClass('card response');
            $(".firstAnswer:contains('?'):first").html(game.dealtResponses[response.cardIDs[0]].text);
    }
    else{
            $(".firstAnswer:contains('?'):first").parent().removeClass('card response unrevealed').addClass('card response');
            $(".firstAnswer:contains('?'):first").html(game.dealtResponses[response.cardIDs[0]].text);
            $(".secondAnswer:contains('?'):first").html(game.dealtResponses[response.cardIDs[1]].text);
    }

    if (game.currentCard.numOfBlanks < 2){
        $('.secondAnswer').hide();
    }
    else{
        $('.secondAnswer').show();
        $(".secondAnswer:contains('?')").hide();
    }
    
    // Keep track of how many cards have been read to determine whether judge can make his/her decision
    game.numReadCards += response.cardIDs.length;

}

// For testing only
function testRevealCard(text){
    //show the response on the TV
    console.log('called testRevealCard:' + text);
     $(".response p:contains('?'):not(:hidden):first").parent().removeClass('card response unrevealed').addClass('card response');
    $(".response p:contains('?'):not(:hidden):first").html(text);


}

function initReceiver(){
    var receiver = new cast.receiver.Receiver('1f96e9a0-9cf0-4e61-910e-c76f33bd42a2', ['com.bears.triviaCast'], "", 5),
        channelHandler = new cast.receiver.ChannelHandler('com.bears.triviaCast'),
        $messages = $('.messages');

    channelHandler.addChannelFactory(
        receiver.createChannelFactory('com.bears.triviaCast'));

    receiver.start();
    console.log('receiver started');

    channelHandler.addEventListener(cast.receiver.Channel.EventType.MESSAGE, onMessage.bind(this));
    channelHandler.addEventListener(cast.receiver.Channel.EventType.ERROR, onError.bind(this));
    channelHandler.addEventListener(cast.receiver.Channel.EventType.CLOSED, onClose.bind(this));

    function onMessage(event) {
        console.log('type = ' + event.message.type);
        console.log(event);

        touch();

        switch(event.message.type){
            case "join":
                joinPlayer(event.target, event.message);
                break;
            case "leave":
                leavePlayer(event.target);
                break;
            case "nextRound":
                startNextRound(event.target);
                break;
            case "updateSettings":
                updatePlayer(event.target, event.message);
                break;
            case "playSubmission":
                playSubmission(event.target, event.message);
                break;
            case "submissionRead":
                revealCard(event.target, event.message);
                break;
            case "submissionsJudged":
                submissionsJudged(event.target, event.message);
                break;
            default:
                event.target.send({ 'type' : 'response', 'code': INVALID_TYPE});
                console.warn("Invalid type: " + event.message.type);
        }
    }

    function onError(event){
        console.error('error received');
        console.debug(event);

        leavePlayer(event.target);
    }

    function onClose(event){
        console.log('Channel disconnected for player');
        console.debug(event);

        leavePlayer(event.target);
    }
}

function initGame(){
    game = new Game();
    newGrind();
}

function hideSplash(){
    $('#splashscreen').fadeOut('slow');
    window.clearTimeout(splashTimeout);
}

function touch(){
    idleTime = 0;
    // TODO: fix this if we want
    // $('#idlewarning').fadeOut();
}

function checkIdle(){
    // Only exit if nobody's in the game (queued doesn't count)
    if(game.players.length > 0){
        return;
    }

    idleTime++;

    if(idleTime > IDLE_MAX){
        window.close();
    }
    else if(idleTime > (IDLE_MAX * .75)){
        // Warn if 75% of the way to exit
        // TODO: fix this if we want
        // $('#idlewarning').fadeIn();
    }
}

// Initialize
$(function(){
    initGame();
    initReceiver();

    // Exit game after inactivity
    var idleInterval = setInterval(checkIdle, 60000); // 1 minute
});

//+ Jonas Raoni Soares Silva
//@ http://jsfromhell.com/array/shuffle [v1.0]
function shuffle(o){
    for(var j, x, i = o.length; i; j = Math.floor(Math.random() * i), x = o[--i], o[i] = o[j], o[j] = x);
    return o;
};
