#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

echo "Enter your username:"
read USERNAME

USER=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

ERROR=0

if [[ $USER ]]
then
  echo "$USER" | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME
  do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
else
  # register the user
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')")

  if [[ $INSERT_USER_RESULT == 'INSERT 0 1' ]]
  then
    echo "Welcome, $USERNAME! It looks like this is your first time here."
  else
    ERROR="Could not save the user. Please try again."
  fi
fi

# checks if there is any error
if [[ $ERROR == 0 ]]
then
  echo "Guess the secret number between 1 and 1000:"
  read NUMBER_GUESSED

  while [[ ! $NUMBER_GUESSED =~ ^[0-9]+$ ]]
  do
    echo "That is not an integer, guess again:"
    read NUMBER_GUESSED
  done

  SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
  TRIES=1

  # locks the user until it correctly guess the number
  while [[ $NUMBER_GUESSED != $SECRET_NUMBER ]]
  do
    if (( $NUMBER_GUESSED < $SECRET_NUMBER ))
    then
      echo "It's higher than that, guess again:"
    else
      echo "It's lower than that, guess again:"
    fi

    read NUMBER_GUESSED

    while [[ ! $NUMBER_GUESSED =~ ^[0-9]+$ ]]
    do
      echo "That is not an integer, guess again:"
      read NUMBER_GUESSED
    done

    TRIES=$(( $TRIES + 1 ))
  done

  echo "You guessed it in $TRIES tries. The secret number was $SECRET_NUMBER. Nice job!"

  GAMES_PLAYED=$($PSQL "SELECT games_played FROM users WHERE username='$USERNAME'")
  BEST_GAME=$($PSQL "SELECT best_game FROM users WHERE username='$USERNAME'")

  if [[ -z $GAMES_PLAYED ]]
  then
    GAMES_PLAYED=1
  else
    GAMES_PLAYED=$(( $GAMES_PLAYED + 1 ))
  fi

  QUERY="UPDATE users SET games_played=$GAMES_PLAYED"

  if [[ -z $BEST_GAME ]]
  then
    QUERY="$QUERY, best_game=$TRIES"
  elif (( $TRIES < $BEST_GAME ))
  then
    QUERY="$QUERY, best_game=$TRIES"
  fi

  QUERY="$QUERY WHERE username='$USERNAME'"
  SAVE_PROGRESS_RESULT=$($PSQL "$QUERY")
else
  echo $ERROR
fi
