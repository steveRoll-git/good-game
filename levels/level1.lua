return {
  title = "Level1",
  width = 7,
  height = 7,
  tiles = {
    1, 1, 1, 1, 1, 1, 1,
    1, 0, 1, 0, 0, 0, 1,
    1, 0, 1, 0, 1, 1, 1,
    1, 0, 1, 0, 0, 0, 1,
    1, 0, 1, 1, 1, 0, 1,
    1, 0, 0, 0, 0, 0, 1,
    1, 1, 1, 1, 1, 1, 1,
  },
  entities = {
    {
      type = "goal",
      x = 5,
      y = 1,
    },
    {
      type = "key",
      x = 3,
      y = 5,
    },
    {
      type = "key",
      x = 5,
      y = 5,
    },
    {
      type = "key",
      x = 4,
      y = 5,
    },
  },
  neededKeys = 3,
  playerX = 1,
  playerY = 1,
  nextLevel = "level2",
}