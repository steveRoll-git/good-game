return {
  title = "Objects of Interest",
  width = 7,
  height = 7,
  tiles = {
    1, 1, 1, 1, 1, 1, 1,
    1, 1, 0, 1, 0, 0, 1,
    1, 1, 0, 1, 1, 0, 1,
    1, 0, 0, 0, 0, 0, 1,
    1, 1, 1, 0, 1, 1, 1,
    1, 1, 1, 0, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1,
  },
  entities = {
    {
      type = "goal",
      x = 4,
      y = 1,
    },
    {
      type = "key",
      x = 2,
      y = 1,
    },
    {
      type = "key",
      x = 3,
      y = 5,
    },
  },
  neededKeys = 2,
  playerX = 1,
  playerY = 3,
  nextLevel = "level3",
}
