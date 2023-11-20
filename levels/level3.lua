return {
  title = "Introduction",
  width = 10,
  height = 7,
  tiles = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 0, 1, 0, 0, 1, 0, 0, 0, 1,
    1, 0, 1, 0, 1, 1, 0, 0, 0, 1,
    1, 0, 1, 0, 0, 1, 0, 0, 0, 1,
    1, 0, 1, 1, 0, 1, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 1, 0, 0, 0, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  },
  entities = {
    {
      type = "goal",
      x = 4,
      y = 1,
    },
    {
      type = "bouncer",
      x = 7,
      y = 1,
    },
    {
      type = "key",
      x = 1,
      y = 5,
    },
    {
      type = "key",
      x = 4,
      y = 5,
    },
    {
      type = "key",
      x = 3,
      y = 3,
    },
  },
  neededKeys = 3,
  playerX = 1,
  playerY = 1,
}
