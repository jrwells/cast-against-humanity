package com.jeffstephens.castagainsthumanity;

import java.io.IOException;
import java.util.ArrayList;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.support.v4.view.MenuItemCompat;
import android.support.v7.app.ActionBarActivity;
import android.support.v7.app.MediaRouteActionProvider;
import android.support.v7.media.MediaRouteSelector;
import android.support.v7.media.MediaRouter;
import android.support.v7.media.MediaRouter.RouteInfo;
import android.util.Log;
import android.view.Menu;
import android.view.MenuItem;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.AdapterView.OnItemClickListener;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.google.cast.ApplicationChannel;
import com.google.cast.ApplicationMetadata;
import com.google.cast.ApplicationSession;
import com.google.cast.CastContext;
import com.google.cast.CastDevice;
import com.google.cast.Logger;
import com.google.cast.MediaRouteAdapter;
import com.google.cast.MediaRouteHelper;
import com.google.cast.MediaRouteStateChangeListener;
import com.google.cast.SessionError;


public class GameActivity extends ActionBarActivity implements MediaRouteAdapter {

	// Debug toggle
	public static final boolean IS_DEBUG = false;

	private static final String TAG = GameActivity.class.getSimpleName();
	private static final Logger sLog = new Logger(TAG, true);
	private static final String APP_NAME = "1f96e9a0-9cf0-4e61-910e-c76f33bd42a2";

	private ApplicationSession mSession;
	private SessionListener mSessionListener;
	private CAHStream mGameMessageStream;

	private CastContext mCastContext;
	private CastDevice mSelectedDevice;
	private MediaRouter mMediaRouter;
	private MediaRouteSelector mMediaRouteSelector;
	private MediaRouter.Callback mMediaRouterCallback;

	// UI elements
	private TextView bigStatus, promptDisplay, judgeBigStatus;
	private Button nextRoundButton;
	private Button sendCardButton;
	private ListView cardList;
	private RelativeLayout cardListHolder;

	// Colors
	private static final int BACKGROUND_ERROR         = 0xFF800000;
	private static final int BACKGROUND_SUCCESS       = 0xFF006600;
	private static final int BACKGROUND_SELECTED_CARD = 0xFFFFFFCC;

	// Game state
	private int playerID = -1;
	private String playerName = null;
	private Card[] hand;
	private int judgeID = -1;
	private ArrayList<Integer> selectedCards = new ArrayList<Integer>();
	private ArrayList<Response> roundResponses = new ArrayList<Response>();
	private int numOfResponses;
	private boolean judgeMode = false;

	// Constants
	private static final String PREF_FILE = "myPreferences";

	/**
	 * Called when the activity is first created. Initializes the game with necessary listeners
	 * for player interaction, and creates a new message stream.
	 */
	@Override
	public void onCreate(Bundle bundle) {
		super.onCreate(bundle);
		setContentView(R.layout.activity_game);

		mSessionListener = new SessionListener();
		mGameMessageStream = new CAHStream();

		mCastContext = new CastContext(getApplicationContext());
		MediaRouteHelper.registerMinimalMediaRouteProvider(mCastContext, this);
		mMediaRouter = MediaRouter.getInstance(getApplicationContext());
		mMediaRouteSelector = MediaRouteHelper.buildMediaRouteSelector(
				MediaRouteHelper.CATEGORY_CAST, APP_NAME, null);
		mMediaRouterCallback = new MediaRouterCallback();

		// Get UI elements
		bigStatus = (TextView) findViewById(R.id.big_status);
		promptDisplay = (TextView) findViewById(R.id.prompt_text);
		judgeBigStatus = (TextView) findViewById(R.id.judge_big_status);
		nextRoundButton = (Button) findViewById(R.id.button_next_round);
		sendCardButton = (Button) findViewById(R.id.button_send_cards);
		cardList = (ListView) findViewById(R.id.card_list);
		cardListHolder = (RelativeLayout) findViewById(R.id.card_list_holder);

		// add listeners
		nextRoundButton.setOnClickListener(new Button.OnClickListener(){
			public void onClick(View v){
				mGameMessageStream.startNextRound();
			}
		});
		sendCardButton.setOnClickListener(new Button.OnClickListener(){
			public void onClick(View v){
				trySubmitCards();
			}
		});

		// load saved stuff
		loadPlayerName();

		// initialize UI
		initScreen();
	}

	private void initScreen(){
		bigStatus.setText(R.string.choose_chromecast);
		bigStatus.setVisibility(View.VISIBLE);
	}

	private void resetGameState(){
		selectedCards.clear();
		roundResponses.clear();
		numOfResponses = 0;
	}

	/**
	 * Called when the options menu is first created.
	 */
	@Override
	public boolean onCreateOptionsMenu(Menu menu) {
		super.onCreateOptionsMenu(menu);
		getMenuInflater().inflate(R.menu.main, menu);
		MenuItem mediaRouteMenuItem = menu.findItem(R.id.media_route_menu_item);
		MediaRouteActionProvider mediaRouteActionProvider =
				(MediaRouteActionProvider) MenuItemCompat.getActionProvider(mediaRouteMenuItem);
		mediaRouteActionProvider.setRouteSelector(mMediaRouteSelector);
		return true;
	}

	@Override
	public boolean onOptionsItemSelected(MenuItem item){
		switch(item.getItemId()){
		case R.id.set_name_media_item:
			updatePlayerName();
			return true;
		default:
			return super.onOptionsItemSelected(item);
		}
	}

	/**
	 * Called on application start. Using the previously selected Cast device, attempts to begin a
	 * session using the application name TicTacToe.
	 */
	@Override
	protected void onStart() {
		super.onStart();
		mMediaRouter.addCallback(mMediaRouteSelector, mMediaRouterCallback,
				MediaRouter.CALLBACK_FLAG_PERFORM_ACTIVE_SCAN);
	}

	/**
	 * Removes the activity from memory when the activity is paused.
	 */
	@Override
	protected void onPause() {
		super.onPause();
		finish();
	}

	/**
	 * Attempts to end the current game session when the activity stops.
	 */
	@Override
	protected void onStop() {
		endSession();
		mMediaRouter.removeCallback(mMediaRouterCallback);
		super.onStop();
	}

	/**
	 * Ends any existing application session with a Chromecast device.
	 */
	private void endSession() {
		if ((mSession != null) && (mSession.hasStarted())) {
			try {
				if (mSession.hasChannel()) {
					mGameMessageStream.leaveGame();
				}
				mSession.endSession();
			} catch (IOException e) {
				Log.e(TAG, "Failed to end the session.", e);
			} catch (IllegalStateException e) {
				Log.e(TAG, "Unable to end session.", e);
			} finally {
				mSession = null;
			}
		}
	}

	/**
	 * Unregisters the media route provider and disposes the CastContext.
	 */
	@Override
	public void onDestroy() {
		MediaRouteHelper.unregisterMediaRouteProvider(mCastContext);
		mCastContext.dispose();
		mCastContext = null;
		super.onDestroy();
	}

	private void setSelectedDevice(CastDevice device) {
		mSelectedDevice = device;
		Log.i(TAG, "setSelectedDevice()");

		if (mSelectedDevice != null) {
			mSession = new ApplicationSession(mCastContext, mSelectedDevice);
			mSession.setListener(mSessionListener);

			try {
				mSession.startSession(APP_NAME);
			} catch (IOException e) {
				Log.e(TAG, "Failed to open a session", e);
			}
		} else {
			endSession();
			Log.e(TAG, "Failed to set selected device.");
		}
	}

	/**
	 * Called when a user selects a route.
	 */
	private void onRouteSelected(RouteInfo route) {
		sLog.d("onRouteSelected: %s", route.getName());
		MediaRouteHelper.requestCastDeviceForRoute(route);
	}

	/**
	 * Called when a user unselects a route.
	 */
	private void onRouteUnselected(RouteInfo route) {
		sLog.d("onRouteUnselected: %s", route.getName());
		setSelectedDevice(null);
	}

	/**
	 * An extension of the MediaRoute.Callback specifically for the Cast Against Humanity game.
	 */
	private class MediaRouterCallback extends MediaRouter.Callback {
		@Override
		public void onRouteSelected(MediaRouter router, RouteInfo route) {
			sLog.d("onRouteSelected: %s", route);
			GameActivity.this.onRouteSelected(route);
		}

		@Override
		public void onRouteUnselected(MediaRouter router, RouteInfo route) {
			sLog.d("onRouteUnselected: %s", route);
			GameActivity.this.onRouteUnselected(route);
		}
	}

	/* MediaRouteAdapter implementation */

	@Override
	public void onDeviceAvailable(CastDevice device, String routeId,
			MediaRouteStateChangeListener listener) {
		sLog.d("onDeviceAvailable: %s (route %s)", device, routeId);
		setSelectedDevice(device);
	}

	@Override
	public void onSetVolume(double volume) {
	}

	@Override
	public void onUpdateVolume(double delta) {
	}

	public void showErrorMessage(String messageText){
		new AlertDialog.Builder(this)
		.setTitle("Uh oh!")
		.setMessage(messageText)
		.setPositiveButton("Dismiss", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) { 
				// do nothing for now
			}
		})
		.show();
	}

	public void showJudgeInstructions(){
		new AlertDialog.Builder(this)
		.setTitle("You Are Judging!")
		.setMessage("Choose the response you think should win this round.")
		.setPositiveButton("Dismiss", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int which) { 
				// do nothing for now
			}
		})
		.show();
	}

	public void showJudgeUI(){
		judgeMode = true;
		sendCardButton.setVisibility(View.VISIBLE);
		cardListHolder.setVisibility(View.VISIBLE);
	}

	/**
	 * A class which listens to session start events. On detection, it attaches the game's message
	 * stream and joins a player to the game.
	 */
	private class SessionListener implements ApplicationSession.Listener {
		@Override
		public void onSessionStarted(ApplicationMetadata appMetadata) {
			sLog.d("SessionListener.onStarted");

			ApplicationChannel channel = mSession.getChannel();
			if (channel == null) {
				Log.w(TAG, "onStarted: channel is null");
				return;
			}
			channel.attachMessageStream(mGameMessageStream);

			requestPlayerNameThenJoinGame();
		}

		@Override
		public void onSessionStartFailed(SessionError error) {
			sLog.d("SessionListener.onStartFailed: %s", error);
		}

		@Override
		public void onSessionEnded(SessionError error) {
			sLog.d("SessionListener.onEnded: %s", error);
		}
	}

	// validate selection, then submit cards
	private void trySubmitCards(){
		if(!judgeMode){
			if(numOfResponses == selectedCards.size()){
				int[] submissionIDs = new int[numOfResponses];
				for(int i = 0; i < numOfResponses; ++i){
					submissionIDs[i] = selectedCards.get(i);
				}
				Log.d(TAG, "Submitting " + numOfResponses + " cards");
				mGameMessageStream.submitResponse(submissionIDs);

				submittedUI();
			}
			else{
				Log.i(TAG, "Tried to submit " + selectedCards.size() + " responses for a prompt that wants " + numOfResponses);
				showErrorMessage("This prompt requires exactly " + numOfResponses + " card(s).\n(You tried to play " + selectedCards.size() +")");
			}
		}
		else{
			// choose winner
			if(selectedCards.size() > 1){
				Log.e(TAG, "More than one winner was in array!");
				showErrorMessage("You're trying to declare more than one winning card. That's bad.");
				return;
			}
			else if(selectedCards.size() < 1){
				Log.e(TAG, "No winner was selected!");
				showErrorMessage("You need to select a winner!");
				return;
			}
			Log.i(TAG, "Declaring user #" + selectedCards.get(0) + " as winner");
			mGameMessageStream.declareWinner(selectedCards.get(0));
			judgeMode = false;
		}
	}

	private void submittedUI(){
		Log.i(TAG, "submittedUI()");
		bigStatus.setText("Waiting on everyone else\nto submit their cards.");
		hideUIShowBigStatus();
	}

	private void hideUIShowBigStatus(){
		Log.i(TAG, "hideUIShowBigStatus()");
		cardListHolder.setVisibility(View.GONE);
		sendCardButton.setVisibility(View.GONE);
		bigStatus.setVisibility(View.VISIBLE);
	}

	private void savePlayerName(String name){
		SharedPreferences settings = getSharedPreferences(PREF_FILE, 0);
		SharedPreferences.Editor editor = settings.edit();
		playerName = name;
		editor.putString("name", name);
		editor.commit();
	}

	private void loadPlayerName(){
		SharedPreferences settings = getSharedPreferences(PREF_FILE, 0);
		playerName = settings.getString("name", null);
	}

	private void requestPlayerNameThenJoinGame(){
		Log.i(TAG, "Requesting player name");

		// only request name if not set
		if(playerName != null){
			mGameMessageStream.joinGame(playerName);
			return;
		}

		AlertDialog.Builder alert = new AlertDialog.Builder(this);

		alert.setTitle("Enter Player Name");
		alert.setMessage("Set your player name to be displayed on the Chromecast.");
		final EditText input = new EditText(this);

		alert.setView(input);

		alert.setPositiveButton("Set Name", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				// check for blank name
				String newName = input.getText().toString();

				// keep asking until a name is supplied
				if(newName.length() == 0){
					showErrorMessage("You've got to supply a name!");
					requestPlayerNameThenJoinGame();
					return;
				}

				savePlayerName(newName);
				Toast.makeText(getApplicationContext(), "Name set to " + playerName, Toast.LENGTH_LONG).show();
				mGameMessageStream.joinGame(playerName);
			}
		});

		alert.create();
		alert.show();
	}

	private void updatePlayerName(){
		Log.i(TAG, "updatePlayerName");

		AlertDialog.Builder alert = new AlertDialog.Builder(this);

		alert.setTitle("Update Player Name");
		alert.setMessage("Set your player name to be displayed on the Chromecast.");
		final EditText input = new EditText(this);

		alert.setView(input);
		if(playerName != null){
			input.setText(playerName);
		}

		alert.setPositiveButton("Change Name", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				// check for blank name
				String newName = input.getText().toString();

				if(newName.length() == 0){
					Toast.makeText(getApplicationContext(), "Didn't update player name.", Toast.LENGTH_LONG).show();
					return;
				}

				if(newName == playerName){
					return;
				}

				savePlayerName(newName);
				Toast.makeText(getApplicationContext(), "Name updated to " + playerName, Toast.LENGTH_LONG).show();
				mGameMessageStream.updateSettings(playerName);
			}
		});

		alert.setNegativeButton("Cancel", new DialogInterface.OnClickListener() {
			public void onClick(DialogInterface dialog, int whichButton) {
				; // do nothing
			}
		});

		alert.create();
		alert.show();
	}

	// update card list with contents of hand, and if any cards are selected highlight them.
	// also update the submit button's contents but don't change its visibility.
	private void updateHandDisplay(){
		Log.i(TAG, "selected cards contains this many items: " + selectedCards.size());

		if(!judgeMode){
			String[] prompts = new String[hand.length];
			for(int i = 0; i < hand.length; ++i){
				prompts[i] = hand[i].toString();
			}

			// populate ListView
			setCardListContents(prompts);

			// set button
			if(selectedCards.size() > numOfResponses){
				int diff = selectedCards.size() - numOfResponses;
				String label = "Select " + Math.abs(diff) + " Less Card";
				if(Math.abs(diff) != 1){
					label += "s";
				}

				sendCardButton.setText(label);
				sendCardButton.setBackgroundColor(BACKGROUND_ERROR);
			}
			else if(selectedCards.size() < numOfResponses){
				int diff = selectedCards.size() - numOfResponses;
				String label = "Select " + Math.abs(diff) + " More Card";
				if(Math.abs(diff) != 1){
					label += "s";
				}

				sendCardButton.setText(label);
				sendCardButton.setBackgroundColor(BACKGROUND_ERROR);
			}
			else{
				String label = "Play " + numOfResponses + " Card";

				if(numOfResponses != 1){
					label += "s";
				}

				sendCardButton.setText(label);
				sendCardButton.setBackgroundColor(BACKGROUND_SUCCESS);
			}
		}
		else{
			if(selectedCards.size() == 1){
				String label = "Choose Winner";
				sendCardButton.setText(label);
				sendCardButton.setBackgroundColor(BACKGROUND_SUCCESS);
			}
			else{
				String label = "Select a Winner";
				sendCardButton.setText(label);
				sendCardButton.setBackgroundColor(BACKGROUND_ERROR);
			}
		}
	}

	private void setCardListContents(String[] contents){
		MyAdapter adapter = new MyAdapter(this, R.layout.list_card, contents);
		cardList.setAdapter(adapter);
		cardList.setOnItemClickListener(mMessageClickedHandler); 
	}

	public class MyAdapter extends ArrayAdapter<String>{

		Context thisContext;

		public MyAdapter(Context context, int resource, String[] objects) {
			super(context, resource, objects);
			thisContext = context;
		}

		@Override
		public View getView(int position, View convertView, ViewGroup parent) {
			View view = super.getView(position, convertView, parent);

			if(judgeMode){
				if(selectedCards.size() > 0){
					Log.i(TAG, roundResponses.get(position).owner + " = " + selectedCards.get(0) + "? " + (roundResponses.get(position).owner == (int) selectedCards.get(0)));
				}
			}

			view.setBackgroundColor(0xFFFFFFFF);
			
			if (judgeMode){
				if(selectedCards.size() > 0){
					if(roundResponses.get(position).owner == (int) selectedCards.get(0)){
						Log.i(TAG, "Setting background color of selected winning card");
						view.setBackgroundColor(BACKGROUND_SELECTED_CARD);
					}
				}
			}
			if(!judgeMode){
				if(!judgeMode && selectedCards.contains(hand[position].id)) {
					Log.i(TAG, "Setting background color of selected card to be played");
					view.setBackgroundColor(BACKGROUND_SELECTED_CARD);
				}
			}

			return view;
		}

	}

	// Create a message handling object as an anonymous class.
	private OnItemClickListener mMessageClickedHandler = new OnItemClickListener() {
		@Override
		public void onItemClick(AdapterView<?> parent, View v, int position, long id) {
			Log.i(TAG, "Clicked item #" + position);
			if(!judgeMode){
				Card thisCard = hand[position];

				// if selected, deselect and vice versa
				if(selectedCards.contains(thisCard.id)){
					selectedCards.remove((Integer) thisCard.id);
				}
				else{
					selectedCards.add(thisCard.id);
				}

				updateHandDisplay();
			}
			else{ // select a winning response
				if(selectedCards.size() > 0){
					selectedCards.clear();
				}

				int responseOwner = roundResponses.get(position).owner;
				selectedCards.add((Integer) responseOwner);

				updateHandDisplay();
			}
		}
	};

	/**
	 * An extension of the GameMessageStream specifically for the TicTacToe game.
	 */
	private class CAHStream extends GameMessageStream {

		// Player is queued. Update UI to notify them.
		protected void onPlayerQueued(){
			bigStatus.setText(R.string.player_queued_notice);
			nextRoundButton.setVisibility(View.VISIBLE);
		}

		// Player has joined. Store ID internally and update UI.
		protected void onPlayerJoined(int newID){
			if(newID < 0){
				Log.w(TAG, "Got negative playerID (" + newID + ")");
				showErrorMessage("Received a negative playerID... that's bad.");
			}
			playerID = newID;
			onRoundEnded();
		}

		// The game has entered judge mode. Update UI.
		protected void onJudgeModeStarted(){
			judgeBigStatus.setVisibility(View.GONE);
			if(playerID == judgeID){
				// let onJudgeResponses handle it
				return;
			}

			bigStatus.setText(R.string.waiting_for_judge);
			hideUIShowBigStatus();
		}

		// Update game state with server information
		protected void onGameSync(JSONObject player, int newJudge){
			judgeID = newJudge;
			try {
				playerID = (int) player.getInt("ID");
				JSONArray handObject = (JSONArray) player.get("hand");

				Card[] newHand = new Card[handObject.length()];

				for(int i = 0; i < handObject.length(); ++i){
					int cardID = handObject.getJSONObject(i).getInt("ID");
					String cardText = handObject.getJSONObject(i).getString("text");
					newHand[i] = new Card(cardID, cardText);
				}

				String logfuck ="newHand:\n";
				for(int i = 0; i < newHand.length; ++i){
					logfuck += newHand[i].toString() + "\n";
				}
				Log.d(TAG, logfuck);

				hand = newHand;

				updateHandDisplay();
			}
			catch (JSONException e) {
				Log.e(TAG, "Couldn't get list of cards in gameSync.");
				showErrorMessage("Couldn't get your updated hand from the server.");
			}
		}

		// Player is judging responses. Display responses and handle submission.
		protected void onJudgeResponses(JSONArray responses){
			showJudgeInstructions();

			try{
				// populate table with responses instead of hand
				ArrayList<Response> responseList = new ArrayList<Response>();
				for(int i = 0; i < responses.length(); ++i){
					JSONObject thisResponseJSONObject = (JSONObject) responses.get(i);
					int thisOwner = thisResponseJSONObject.getInt("submitter");

					JSONArray thisCardsArray = (JSONArray) thisResponseJSONObject.get("cards");
					Card[] theseCards = new Card[thisCardsArray.length()];
					int[] theseCardIDs = new int[thisCardsArray.length()];
					for(int j = 0; j < thisCardsArray.length(); ++j){
						JSONObject thisCardJSONObject = (JSONObject) thisCardsArray.get(j);
						int thisCardId = thisCardJSONObject.getInt("ID");
						String thisCardPrompt = thisCardJSONObject.getString("text");
						theseCards[j] = new Card(thisCardId, thisCardPrompt);
						theseCardIDs[j] = thisCardId;
					}

					Response thisResponse = new Response(thisOwner, theseCards);
					Log.i(TAG, thisResponse.toString());
					responseList.add(thisResponse);
					roundResponses.add(thisResponse);

					// mark as read on server
					mGameMessageStream.readSubmission(theseCardIDs);
				}

				String[] responseStrings = new String[responseList.size()];
				for(int i = 0; i < responseList.size(); ++i){
					String tempString = new String();

					for(int j = 0; j < responseList.get(i).contents.length; ++j){
						tempString += responseList.get(i).contents[j];

						if(j < (responseList.get(i).contents.length - 1)){
							tempString += "\n";
						}
					}

					responseStrings[i] = tempString;
				}

				showJudgeUI();
				setCardListContents(responseStrings);
			}
			catch (JSONException e){
				Log.e(TAG, "Couldn't get list of responses in onJudgeResponses.");
				showErrorMessage("There was a problem getting everyone's responses from the server.");
			}
		}

		// The round has started. Display the new prompt and the player's hand.
		protected void onRoundStarted(String newPrompt, int numOfBlanks){
			promptDisplay.setText(newPrompt);
			promptDisplay.setVisibility(View.VISIBLE);
			bigStatus.setVisibility(View.GONE);
			nextRoundButton.setVisibility(View.GONE);

			numOfResponses = numOfBlanks;
			updateHandDisplay();

			if(playerID == judgeID){
				Log.i(TAG, "I'm judge!");
				judgeBigStatus.setVisibility(View.VISIBLE);
				numOfResponses = 1;
				return;
			}

			Log.i(TAG, "Showing cardListHolder");
			sendCardButton.setVisibility(View.VISIBLE);
			cardListHolder.setVisibility(View.VISIBLE);
		}

		// The round has ended. Update UI.
		protected void onRoundEnded(){
			bigStatus.setText(R.string.waiting_for_round);
			bigStatus.setVisibility(View.VISIBLE);
			nextRoundButton.setVisibility(View.VISIBLE);
			sendCardButton.setVisibility(View.GONE);
			cardListHolder.setVisibility(View.GONE);
			promptDisplay.setVisibility(View.GONE);

			resetGameState();
		}

		// Some error code has been received. Let the user know.
		protected void onServerError(int errorCode){
			String messageText;
			switch(errorCode){
			case ERROR_SENT_INVALID_MESSAGE_TYPE:
				messageText = "Something went wrong with the code...";
				Log.e(TAG, "ERROR_SENT_INVALID_MESSAGE_TYPE");
				break;
			case ERROR_WRONG_NUMBER_OF_CARDS:
				messageText = "You tried to submit the wrong number of cards.";
				break;
			case ERROR_INVALID_WINNER_SUBMITTED:
				messageText = "You tried to declare yourself or a nonexistent player as winner.";
				break;
			case ERROR_JUDGED_BEFORE_CARDS_WERE_READ:
				messageText = "You tried to declare a winner before reading all the cards.";
				break;
			case ERROR_TRIED_TO_JOIN_WITH_BLANK_NAME:
				messageText = "You tried to join the game with a blank name.";
				break;
			case ERROR_TRIED_TO_START_ROUND_WHILE_ROUND_EXISTS:
				messageText = "You can't start a round while one is in progress.";
				break;
			case ERROR_TRIED_TO_START_ROUND_INSUFFICIENT_PLAYERS:
				messageText = "There aren't enough players to start the round yet.";
				break;
			default:
				messageText = "An unknown error occurred.";
			}

			showErrorMessage(messageText);
		}

	}
}
