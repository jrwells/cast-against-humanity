package com.jeffstephens.castagainsthumanity;

public class Response{
	public int owner;
	public Card[] contents;
	
	public Response(int owner, Card[] contents){
		this.owner = owner;
		this.contents = contents;
	}
	
	public String toString(){
		return this.owner + ": " + this.contents;
	}
}