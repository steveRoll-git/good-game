return {
  title = "Enclosed",
  width = 10,
  height = 10,
  tiles = {
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 0, 0, 0, 0, 0, 0, 0, 0, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
  },
  entities = {
    {
      type = "goal",
      x = 1,
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
      y = 6,
    },
    {
      type = "key",
      x = 4,
      y = 3,
    },
    {
      type = "key",
      x = 7,
      y = 8,
    },
  },
  neededKeys = 3,
  playerX = 1,
  playerY = 1,
}
