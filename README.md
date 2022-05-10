# Techpet Global DevOps Interns Challenge Part 4

## Ceros Devops Code Challenge

Contained within is a functional infrastructure for the ceros-ski nodejs game. We believe that beyound writing infrastructure codes is doing so in an optimal way and hence, the purpose for this task. What we'd like you to do is restructure the `infrastructure/environment` and `infrastructure/repositories` to follow terraform code best practices.

## The Task

1. Fork this repo

2. The ceros-ski game can be loaded successfully in a browser after following the instructions in [usage.md](usage.md). 

3. Create two files named `${firstname}_${lastname}_optimization.md` and `${firstname}_${lastname}_suggestions.md`. `${firstname}_${lastname}_optimization.md` will be used to document all optimization changes you made. `${firstname}_${lastname}_suggestions.md` will be used to document any techdebt decisions you made while working on this project. 

4. Optimize the directories to suit terraform code best practise (near/or production-grade)


## Acceptance Criteria

You can consider the challenge "done" when each of these has been achieved.

- Access to the ceros-ski game without modifying any file.
- A remote backend with state lock is configured to store the state files of the directories in view.
- Implementation of reuseable modules for the directories in view.
- The infrastructure is highly available.
- Architectural diagram follows the well-architected framework.
- A 10 year old would understand the contents of your optimization.md file without numerous googling.

## Grading

You will be graded on the following criteria.

- How well optimized the directories are.
- What has been pulled out into terraform modules, and how well structured those modules are.
- How well security concerns have been handled.
- The quality, detail, and clarity of your optimization documentation.
- How well documented and reasonable tech debt decisions (if any) are.

## Bonus

Suprise us with something different, new and interesting :)
