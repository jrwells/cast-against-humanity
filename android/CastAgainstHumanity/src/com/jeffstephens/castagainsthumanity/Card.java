package com.jeffstephens.castagainsthumanity;


/* A Card is a white response card. The ID and prompt are received from the Chromecast. */
public class Card {
	public int id;
	public String prompt;

	public Card(int id, String prompt){
		this.id = id;
		this.prompt = prompt;
	}

	public String toString(){		
		if(GameActivity.IS_DEBUG){
			return this.id + ": " + this.prompt;
		}
		else{
			return this.prompt;
		}
	}
}
