import gleeunit/should
import twinkle_pub/utils

pub fn get_last_query_param_test() {
  let params_two_no_duplicates = [#("foo", "true"), #("bar", "false")]
  let params_three_one_duplicate = [
    #("foo", "true"),
    #("bar", "false"),
    #("bar", "true"),
  ]

  utils.get_last_query_param(params_two_no_duplicates, "foo")
  |> should.equal(Ok("true"))

  utils.get_last_query_param(params_three_one_duplicate, "bar")
  |> should.equal(Ok("true"))
}
