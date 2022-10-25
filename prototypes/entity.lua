local bufferCombinator = flib.copy_prototype(data.raw["constant-combinator"]["constant-combinator"], "buffer-combinator")
bufferCombinator.fast_replaceable_group = "constant-combinator"

local bufferCombinatorItem = flib.copy_prototype(data.raw["item"]["constant-combinator"], "buffer-combinator")

local bufferCombinatorRecipe = flib.copy_prototype(data.raw["recipe"]["constant-combinator"], "buffer-combinator")
bufferCombinatorRecipe.ingredients = {
  {"constant-combinator", 1},
  {"electronic-circuit", 1},
}

data:extend({
  bufferCombinator,
  bufferCombinatorItem,
  bufferCombinatorRecipe,
})
