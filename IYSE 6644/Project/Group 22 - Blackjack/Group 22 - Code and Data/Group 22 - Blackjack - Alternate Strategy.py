import random
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd

def deal(deck, hand):
    random.shuffle(deck)
    hand.append(deck.pop())
    return hand

def play():
    player_hand = []
    dealer_hand = []

    deck = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'] * 4

    # Deal players hand
    for i in range(2):
        deal(deck, player_hand)

    # Deal dealers hand
    for i in range(2):
        deal(deck, dealer_hand)

    # Count players cards
    player_cnt = 0
    for i, card in enumerate(player_hand):
        if card.isnumeric():
            player_cnt += int(card)
        else:
            if card in ['J', 'Q', 'K']:
                player_cnt += 10
            # Decide what to do with an ace, play as 11 if total will be greater than or equal to 17
            elif (card == 'A') & ((player_cnt >= 6) | (player_cnt == 0)):
                player_cnt += 11
            else:
                player_cnt += 1

    # Count dealers carts
    dealer_cnt = 0
    for i, card in enumerate(dealer_hand):
        # Check to see if the card is a "face" (A, J, Q, K) or numeric card (i.e., 2-10) card and add to count
        if card.isnumeric():
            dealer_cnt += int(card)
        else:
            if card in ['J', 'Q', 'K']:
                dealer_cnt += 10
            # Decide what to do with an ace, play as 11 if total will be greater than or equal to 17
            elif (card == 'A') & ((player_cnt >= 6) | (player_cnt == 0)):
                dealer_cnt += 11
            else:
                dealer_cnt += 1

        # Show the dealers first card
        if i == 0:
            dealer_first = dealer_cnt
            dealer_first_card = card

    # Hit when the players count is less than 17 and the dealers first card is greater than 6; otherwise stay
    # initialize hit or stay criteria
    stay = 0
    while stay == 0:
        # Hit if count of cards is less than 17 and dealer up card is greater than 6
        if ((player_cnt < 17) & (dealer_first > 6)): # then hit
            # Deal next card
            next_card = deck.pop()

            # Append next card to player hand
            player_hand.append(next_card)

            # Count the same way as above
            if next_card.isnumeric():
                player_cnt += int(next_card)
            else:
                if next_card in ['J', 'Q', 'K']:
                    player_cnt += 10
                # Decide what to do with an ace
                elif (next_card == 'A') & (player_cnt <= 10):
                    player_cnt += 11
                else:
                    player_cnt += 1

        # Hit if Soft 18 and dealer 9, 10, or A
        elif ((player_hand[0] == 'A') & (player_hand[1] == '7') & (dealer_first_card in ['9', '10', 'A']) & (len(player_hand) == 2)) | ((player_hand[0] == '7') & (player_hand[1] == 'A') & (dealer_first_card in ['9', '10', 'A']) & (len(player_hand) == 2)):
            # Deal next card
            next_card = deck.pop()

            # Append next card to player hand
            player_hand.append(next_card)

            # Count the same way as above
            if next_card.isnumeric():
                player_cnt += int(next_card)
            else:
                if next_card in ['J', 'Q', 'K']:
                    player_cnt += 10
                # Decide what to do with an ace
                elif (next_card == 'A') & (player_cnt <= 10):
                    player_cnt += 11
                else:
                    player_cnt += 1

        else:
            stay = 1

    # Allow the dealer to hit until they are greater than 17
    while dealer_cnt < 17:
        next_card = deck.pop()
        dealer_hand.append(next_card)
        if next_card.isnumeric():
            dealer_cnt += int(next_card)
        else:
            if next_card in ['J', 'Q', 'K']:
                dealer_cnt += 10
           # Decide what to do with an ace
            elif (next_card == 'A') & (player_cnt <= 10):
                dealer_cnt += 11
            else:
                dealer_cnt += 1

    # If the players cards equal 21 and they were only deal two cards than it is a black jack
    if (player_cnt == 21) & (len(player_hand) == 2):
        return player_hand, dealer_hand, "Blackjack!", 1
    # If the players cards are greater than 21 then they busted. Must be tested before dealers
    elif player_cnt > 21:
        return player_hand, dealer_hand, "Loser - Bust", -1
    # If the dealers cards are greater than 21 then they busted
    elif dealer_cnt > 21:
        return player_hand, dealer_hand, "Winner - Dealer Bust", 1
    # If neither the dealer nor player busted and the player has the greater count then they won
    elif player_cnt > dealer_cnt:
        return player_hand, dealer_hand, "Winner - Closer to 21", 1
    # If neither the dealer nor player busted and the dealer has the greater count then they won
    elif player_cnt < dealer_cnt:
        return player_hand, dealer_hand, "Loser - Dealer closer to 21", -1
    # If the player and dealer both have the same count then it is a draw
    elif player_cnt == dealer_cnt:
        return player_hand, dealer_hand, "Draw", 0


def test_play(num_games):
    win_cnt = 0
    lose_cnt = 0
    draw_cnt = 0
    blackjack_cnt = 0
    bet = 10
    winnings = 0

    for i in range(num_games):
        _, _, result_str, result = play()
        if result > 0:
            win_cnt += 1
        elif result < 0:
            lose_cnt += 1
        else:
            draw_cnt += 1

        if result_str == 'Blackjack!':
            blackjack_cnt += 1
            winnings += bet * result * 1.25 # Get more money back for a black jack
        else:
            winnings += bet * result

    return round((win_cnt / num_games) * 100, 2)

sim_test_games = np.linspace(1000, 100000, num=100, dtype=int)
print(sim_test_games)
sim_test_results = []

for num_games in sim_test_games:
    result = test_play(num_games)
    sim_test_results.append(result)

d = {'Simulations': sim_test_games, 'Results': sim_test_results}
df = pd.DataFrame(data=d)

df.to_csv('Alternative_Strategies_Results.csv')

plt.plot(sim_test_games, sim_test_results)
plt.ylabel("Win Percentage")
plt.xlabel("Number of Games Played")

plt.show()

#print('********************************************************************************')
#print('***** The win percentage is: %', round((win_cnt / num_games) * 100, 2))
#print('***** The percentage of blackjacks was: %', round((blackjack_cnt/ num_games) * 100, 2))
#print('***** The net proceeds were: $', winnings)
#print('********************************************************************************')

