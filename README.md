# Royal Sort

<img width="800" height="319" alt="royalSortExample" src="https://github.com/user-attachments/assets/7e176835-5c7d-4279-bf0f-3b65ac9b93b1" />

Royal Sort sorts your cards into three piles:
- Queens
- Kings
- Jacks, Aces, and numbered cards

Select this sorting method when using a Shoot the Moon or Baron build. It's especially nice when transitioning between the two!

## Full Sorting Algorithm
1. Sort cards into three piles: queens, kings, and garbage
2. Sort the piles by the following rules:
   - Queens and Kings
      1. enhancement
      2. seal
      3. suit
   - Garbage
      1. rank
      2. suit
      3. enhancement
      4. seal
3. Union the piles back together

## Sort Priorities
```lua
--lower numbers get higher priority
seal = {
    Blue = 1, Purple = 2, Gold = 3, Red = 4,
},
suit = {
    Spades = 1, Hearts = 2, Clubs = 3, Diamonds = 4
},
rank = {
    Ace = 1,
    King = 2,
    Queen = 3,
    Jack = 4,
    [10] = 5,
    [9] = 6,
    [8] = 7,
    [7] = 8,
    [6] = 9,
    [5] = 10,
    [4] = 11,
    [3] = 12,
    [2] = 13
},
enhancement = {
    m_gold = 2,
    m_glass = 3,
    m_wild = 4,
    m_bonus = 5,
    m_mult = 6,
    m_lucky = 7,
    m_steel = 8,
    m_stone = 9,
},
```
