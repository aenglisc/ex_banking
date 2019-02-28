# ExBanking

Test task for Elixir developers. Candidate should write a simple banking OTP application in Elixir language.

### Notes and things I don't like in the current solution:

  * There is no proper supervision tree as of now, although it might be a good idea to add one. In particular, it might help with the issue that if the recipient crashes after the sender moves its funds to pending, the funds will be stuck in pending. More than that, the calling process will never receive a reply in this case.
  * Not sure about rounding with floats. 1.777 can either be considered a 1.77 or a 1.78, I chose the default behaviour of `Decimal`, which is to round it up.
  * `handle_call`s in the producer can be unified, however the `:send` would still require a separate callback as it returns a different error tuple on overload. Might come up with a more elegant solution later.
  * Binding on a pattern match, such as `{:ok, producer} = ExBanking.User.Producer.start_link(name)` is an antipattern but I left them as is since they seemed safe enough.

## General acceptance criteria

  * All code is in git repo (candidate can use his/her own github account).
  * OTP application is a standard mix project.
  * Application name is :ex_banking (main Elixir module is ExBanking).
  * Application interface is just set of public functions of ExBanking module (no API endpoint, no REST / SOAP API, no TCP / UDP sockets, no any external network interface).
  * Application should not use any database / disc storage. All needed data should be stored only in application memory.
  * Candidate can use any Elixir or Erlang library he/she wants to (but app can be written in pure Elixir / Erlang / OTP).
  * Solution will be tested using our auto-tests for this task. So, please follow specifications accurately.
  * Public functions of ExBanking module described in this document is the only one thing tested by our auto-tests. If anything else needs to be called for normal application functioning then probably tests will fail.
  * Code accuracy also matters. Readable, safe, refactorable code is a plus.

## Money amounts

  * Money amount of any currency should not be negative.
  * Application should provide 2 decimal precision of money amount for any currency.
  * Amount of money incoming to the system should be equal to amount of money inside the system + amount of withdraws (money should not appear or disappear accidentally).
  * User and currency type is any string. Case sensitive. New currencies / users can be added dynamically in runtime. In the application, there should be a special public function (described below) for creating users. Currencies should be created automatically (if needed).

## Performance

  * In every single moment of time the system should handle 10 or less operations for every individual user (user is a string passed as the first argument to API functions). If there is any new operation for this user and he/she still has 10 operations in pending state - new operation for this user should immediately return too_many_requests_to_user error until number of requests for this user decreases < 10
  * The system should be able to handle requests for different users in the same moment of time
  * Requests for user A should not affect to performance of requests to user B (maybe except send function when both A and B users are involved in the request)
