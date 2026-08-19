# Guidelines

## Regarding agent responses

- Agent responses must be concise, direct and non-technical
- Assume the operator is non technical (in terms of programming) unless explicitly stated. Feel free to push back if you think an architectural decision is flawed.
- Assume the operator has Godot and Visual Studio Code. If necessary, instruct them on how to use them to perform any necessary actions and/or validations.
- Politely point out spelling mistakes and/or odd text decisions

## Regarding code 

- Most behaviours should be exposed for edition in the editor. You are in charge of keeping a good UX regarding game designer experience for game customization.
- Maintain separation of concerns across classes
- You are responsible for code quality. You must be proactive to decide upon code quality:
    - If separation of concerns is violated, refactor
    - If classes become god classes, refactor

