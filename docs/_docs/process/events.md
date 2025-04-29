---
title: Events
category: Process
order: 3
---

# The Sprint Cycle

The sprint cycle is the foundational rhythm of the scrum process. Whether you call your development period a sprint, a cycle or an iteration, you are talking about exactly the same thing: a fixed period of time within which you bite off small bits of your project and finish them before returning to bite off a few more. At the end of your sprint, you will be demonstrating working software or thy name is Mud.

The more frequently the team delivers a potentially shippable product increment, the greater freedom the business has in deciding when and what to ship. Notice that there are 2 separate decisions here:

    Is the product potentially shippable? That is to say, is the quality high enough that the business could ship it? Are all of the current stories done? This is a decision for the team.
    Does it make business sense to ship what we have at this time? Is there enough incremental value present to take the current product to market? This is a decision for the business.

Additionally, the more frequently the team delivers and demonstrates a potentially shippable product increment, the more frequently the team gets feedback, which fuels the important inspect-and-adapt cycle. The shorter the sprint cycle, the more frequently the team is delivering value to the business.

As of this writing, it is common for scrum teams to work in sprints that last two weeks, and many teams are starting to work in one-week sprints. Much of the original writing about scrum assumed a month-long sprint, and at the time that seemed very short indeed!

The table below maps out the various meetings you would schedule during a one-week sprint. You don’t have to call them meetings if you’re allergic to the term or consider meetings to be a form of repetitive stress injury; you can call them ceremonies, as many scrum adherents do. The meeting lengths shown are an appropriate starting point for a team doing one-week sprints.

## Sprint Planning Meeting

Sprint planning marks the beginning of the sprint. Commonly, this meeting has two parts. The goal of the first part is for the team to commit to a set of deliverables for the sprint. During the second part of the meeting, the team identifies the tasks that must be completed in order to deliver the agreed upon user stories. We recommend one to two hours of sprint planning per week of development.
Part One: “What will we do?”

The goal of part one of the sprint planning meeting is to emerge with a set of “committed” stories that the whole team believes they can deliver by the end of the sprint. The product owner leads this part of the meeting.

One by one, in priority order, the product owner presents the stories he would like the team to complete during this sprint. As each story is presented, the team members discuss it with the product owner and review acceptance criteria to make sure they have a common understanding of what is expected. Then the team members decide if they can commit to delivering that story by the end of the sprint. This process repeats for each story, until the team feels that they can’t commit to any more work. Note the separation in authority: the product owner decides which stories will be considered, but the team members doing the actual work are the ones who decide how much work they can take on.
Part 2: “How will we do it?”

In phase two of the sprint planning meeting, the team rolls up its sleeves and begins to decompose the selected stories into tasks. Remember that stories are deliverables: things that stakeholders, users, and customers want. In order to deliver a story, team members will have to complete tasks. Task are things like: get additional input from users; design a new screen; add new columns to the database; do black-box testing of the new feature; write help text; get the menu items translated for our target locales; run the release scripts.

The product owner should be available during this half of the meeting to answer questions. The team may also need to adjust the list of stories it is committing to, as during the process of identifying tasks the team members may realize that they have signed up for too many or too few stories.

The output of the sprint planning meeting is the sprint backlog, the list of all the committed stories, with their associated tasks. The product owner agrees not to ask for additional stories during the sprint, unless the team specifically asks for more. The product owner also commits to being available to answer questions about the stories, negotiate their scope, and provide product guidance until the stories are acceptable and can be considered done.

## Daily Scrum

The daily scrum, sometimes called the stand-up meeting, is:

Daily. Most teams choose to hold this meeting at the start of their work day. You can adapt this to suit your team’s preferences.

Brief. The point of standing up is to discourage the kinds of tangents and discursions that make for meeting hell. The daily scrum should always be held to no more than 15 minutes.

Pointed. Each participant quickly shares:

    Which tasks I've completed since the last daily scrum.
    Which tasks I expect to complete by the next daily scrum.
    Any obstacles are slowing me down.

The goal of this meeting is to inspect and adapt the work the team members are doing, in order to successfully complete the stories that the team has committed to deliver. The inspection happens in the meeting; the adaptation may happen after the meeting. This means that the team needn't solve problems in the meeting: simply surfacing the issues and deciding which team members will address them is usually sufficient. Remember, this meeting is brief!

## Story Time

In this meeting you will be discussing and improving the stories in your product backlog, which contains all the stories for future sprints. Note that these are not the stories in the current sprint–those stories are now in the sprint backlog. We recommend one hour per week, every week, regardless of the length of your sprint. In this meeting, the team works with the product owner on:

### Acceptance Criteria

Each user story in the product backlog should include a list of acceptance criteria. These are pass/fail testable conditions that help us know when then the story is implemented as intended. Some people like to think of them as acceptance examples: the examples that the team will demonstrate to show that the story is done.

### Story Sizing (Estimation)

During story time, the team will assign a size (estimate, if you prefer that term) to stories that haven’t yet been sized. This is the team's guess at how much work will be required to get the story completely done.

### Story Splitting

Stories at the top of the product backlog need to be small. Small stories are easier for everyone to understand, and easier for the team to complete in a short period of time. Stories further down in the product backlog can be larger and less well defined. This implies that we need to break the big stories into smaller stories as they make their way up the list. While the product owner may do much of this work on their own, story time is their chance to get help from the whole team.

As of this writing, the story time meeting isn’t an 'official' scrum meeting. We suspect it will be in the future, as all of the high performing scrum teams we know use the story time meeting to help keep their product backlog groomed.

## Sprint Review

This is the public end of the sprint; invite any and all stakeholders to this meeting. It's the team's chance to show off its accomplishments, the stories that have met the team's definition of done. This is also the stakeholders’ opportunity to see how the product has been incrementally improved over the course of the sprint.

If there are stories that the team committed to but did not complete, this is the time to share that information with the stakeholders. Then comes the main event of this meeting: demonstrating the stories that did get done. Undoubtedly the stakeholders will have feedback and ideas, and the product owner and the team members will gather this feedback, which will help the team to inspect-and-adapt the product.

This meeting is not a decision-making meeting. It's not when we decide if the stories are done; that must happen before this meeting. It's not when we make decisions or commitments about what the team will do during the next sprint; that happens in sprint planning.

How long should the sprint review be? We recommend scheduling one-half to one hour for every week of development. That is, if you have a one-week sprint, then this meeting might be 30 – 60 minutes. If you have a two-week sprint, then this meeting might need one to two hours. After you have done it a few times, you will know how long your team needs–inspect and adapt!

## Retrospective

While the sprint review is the public end of the sprint, the team has one more meeting: the retrospective. Scrum is designed to help teams continuously inspect and adapt, resulting in ever-improving performance and happiness. The retrospective, held at the very end of each and every sprint, is dedicated time for the team to focus on what was learned during the sprint, and how that learning can be applied to make some improvement. We recommend one to two hours of retrospective time for each week of development.

Unlike the traditional “post mortem,” the aim of a retrospective is never to generate a long laundry list of things that went well and things that went wrong, but to identify no more than one or two strategic changes to make in the next sprint. It’s about process improvement.
Abnormal Sprint Termination: When Good Sprints Go Bad

In scrum, the basic agreement between management and the team is that management won’t change up requirements during a sprint. Still, every once in a while something happens that invalidates everything in the sprint plan—a business is sold, a game-changing technology enters the market, a competitor makes a move. The decision to terminate the sprint early is fundamentally a business decision, so the product owner gets to make the call on an “abnormal sprint termination.” Despite the name, neither Arnold Schwarzenegger nor James Cameron need get involved.

If the product owner does decide to terminate the sprint early, the team will back out any changes that they have made during the sprint to avoid the problems that come from half-done work. Holding a retrospective is especially important after a sprint is abnormally terminated, as it helps the team learn from the experience.
Inspect & Adapt, Baby

So, why do we do development work in these short cycles? To learn. Experience is the best teacher, and the scrum cycle is designed to provide you with multiple opportunities to receive feedback—from customers, from the team, from the market—and to learn from it. What you learn while doing the work in one cycle informs your planning for the next cycle. In scrum, we call this “inspect and adapt”; you might call it “continuous improvement”; either way, it’s a beautiful thing.
