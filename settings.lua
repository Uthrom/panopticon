Constants = require("constants")

data:extend({
  {
    name = "panopticon-rechart-interval",
    type = "int-setting",
    setting_type = "runtime-global",
    default_value = Constants.RechartInterval,
    minimum_value = 10,
    maximum_value = 600,
    order = "1101"
  }
})

