import twinkle_pub/utils

pub fn get_last_query_param_test() {
  let params_two = [#("foo", "true"), #("bar", "false")]
  let params_three = [
    #("foo", "true"),
    #("bar", "false"),
    #("bar", "true"),
  ]

  let assert Ok("true") = utils.get_last_query_param(params_two, "foo")
  let assert Ok("true") = utils.get_last_query_param(params_three, "bar")
  let assert Error(Nil) = utils.get_last_query_param(params_two, "missing")
}
