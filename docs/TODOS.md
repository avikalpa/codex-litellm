# Polish
1. (done) We should not require a config.toml file. Just like codex, during the first session we should ask the user for the litellm endpoint and API_KEY.
2. We should also be able to change these parameters by /logout and then restarting a codex session.
3. In upstream codex when we /quit a session, the session can be resumed using codex resume (this works). During quitting, it tells the user that we can codex resume <UUID>.
4. (done) We should be able to change models using /models like in upstream codex. In the first session, we should ask the user by querying the litellm endppoint and receiving the models which model should be the default for this and future sessions.
5. (done) Similarly, /status should surface LiteLLM usage stats just like upstream codex does.
6. (done) /model selector will be in two stages, just like in upstream codex. First model selection, and then low, medium, and high thinking; defaulting to medium. Assume all models have 130k context window.
7. We should also adjust the session context of upstream codex to 130k and then auto compact. There should be an option in config.toml to adjust context window of patched codex. Because each model supports different context length. 130k is the lowest common denominator. Hence our default. I think currently upstream codex has context window of 400k matching their gpt models.
8. When resuming a upstream codex session, we should check if the existing context window is above our context window limit. If yes, the user should be asked the session is over the context window limit of the litellm version and whether to compress it or exit.
9. (done) Where version info is shown in the program, instead of showing only the upstream version like v0.0.50 it should show upstream+our_commit_id like v0.0.50+cd6y5t
10. (done) Improvement over 1. Use the Ascii startup onboarding but modified with intructions and options for our use-case.
11. TUI status bar bug: shows 100% context always. We should check context handling logic with point 6 & 7.
