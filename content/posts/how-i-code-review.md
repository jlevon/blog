---
title: "How I Code Review"
date: 2022-02-05
draft: true
---

I thought it might be interesting, at least to myself, to write up how I
approach code reviews. My history in tech is one where close code review was
emphasized and well-respected: most appreciated that a detailed review was not
only worth the reviewer's time, but mutually beneficial, and often a great
learning experience for everyone. So my tiny mind can't process ideas like
[post-commit
reviews](https://copyconstruct.medium.com/post-commit-reviews-b4cc2163ac7a),
that seem to be predicated on the idea that testing is some kind
of replacement for code review. To me, the kind of things that tests can cover
is only a very small part of what code review is useful for.

I've code-reviewed entire projects totalling many thousands of lines, and
single-character changes, but I'm usually following at least some of the below
patterns either way:

# Understand the context

First thing I read is the commit message. Of course, this should be in [normal
form](https://cbea.ms/git-commit/), but I'm really making sure I can understand
what the change is, based solely upon the commit message. Without looking at the
code, can I, as a casual observer, understand what's changed? Is the commit
title specific enough? Does the commit message's contents describe not just
*what* changed, but *why* (as usual, the GNU standard is an exemplar of what not
to do here)? Is it clear? Does the message needlessly have things that belong on
another tracking system (target gate)?

I will read any associated ticket for its context - especially keeping an eye
out for anything that doesn't seem to fit with the PR's changes. This could be a
missing case, or a fundamental mis-understanding of what the real underlying
problem is. If there is any design doc mentioned (and they should be mentioned!)
I'll also read that and `diff` its contents against what actually got
implemented.

I'm looking mainly for disparities between what everyone agreed we should do,
and what is actually happening in the code, but especially for missing things;
it's very easy to accidentally skip somebody's drive-by comment, but that could
turn out to be crucial to the implementation.

I also consider if this change makes sense on its own, and if it could be split
up: this is often a matter of appetite (and personally I find the Linux kernel
approach often goes a little too far), but patch series with one logical change
per commit is often much easier to review. It should hopefully go without saying
that each individual commit in the series should still pass CI, but
unfortunately that's painful to do with at least [github
PRs](https://movementarian.org/blog/posts/github-prs/).

# Get an overview

Next I start looking at the actual code changes: often with [one tab per
file](https://movementarian.org/blog/posts/2019-10-22-open-all-links-in-gerrit/),
I'm trying to understand how the changes fit together: who calls what, what new
intra-code dependencies there are, what the possible impact of the changes could
be.

I might well look back in git history for each of these files to understand why
the old code is like it is: this is also often very useful in identifying
potential issues with the new changes.

Depending on the change, I will often checkout a local copy, and use `git grep`,
`ctags`, etc. to help me understand how everything fits together.

My focus at this level is often on interfaces: does a new method have a suitable
name? Is it at the right level of abstraction? What is the ownership of the
relevant objects? Are there any layering violations?

Are there any external dependencies we need to worry about? Equally if anyone is
depending on us, are we providing well-written interfaces? Are they designed
with care and attention to versioning, information hiding, and all the usual API
concerns? Is this going to wear well after it's been in production for years?

I'm also bearing in mind other ongoing work: if there's a project underway that
is directly relevant to this specific change, I might ask for some accommodation
that will make the eventual merge of both easier. Equally if there's a general
desire to take a particular technical direction, I might complain if something
is taking a different tack.

It's a rare code review where I don't have to pause to go research something:
`systemd` service definition semantics, syscall error modes, how `selinux` roles
work etc. As I said above, great learning experience!

Are there potential performance concerns with the change: lots of unnecessary
I/O, potential for big-O issues, needless overhead etc? What are the expected
limits of the objects being handled?

What if there are bugs with this change: is the error handling suitable? Is
there a sufficient level of logging, exception details, etc. to identify in the
field what went wrong? Is there unnecessary noise? How would a stressed-out SRE
deal with this in production?

Have any necessary unit/component tests been updated or added? Do they actually
test something useful?

I almost *never* build or test changes I'm reviewing: that's a job for the
submitter and your CI infrastructure. The only exception is if I'm struggling to
understand something, and running the tests would help.

# Detailed review

I'm now going to go line-by-line through the whole patch, leaving comments where
necessary. Sometimes I'll reach something I don't understand, add leave a
"FIXME" for myself: if, after reading the whole change, I still don't understand
what's happening, this will often re-formulate itself into a question for the
submitter, along with a request for expanded code comments, but usually I can
just delete these later.

If I find major - architectural level - issues with what I'm looking at, that's
often a good prompt to take the discussion elsewhere, perhaps to a Zoom call or
design document discussion. Doing design review inside a PR is not fun for
anyone.

I've noticed a tendency to "review the diffs": the idea that only the changed
lines are relevant to the review - that tools expand 10 lines at a time is a
symptom of this. This is very wrong-headed in my opinion, and I often find
myself in the rest of the code to make sure I can properly review what *has*
changed.

# Comb for nits

Everyone has a different appetite for code review nits: generally, I will always
point out actual typos (often just once, if it's repeated, expecting the
submitter to apply my comment to all instances). If I have a substantive
comment, I might also suggest some style-level improvements. I never expect
someone to make these sort of changes for existing code: the general idea is to
leave the code in a slightly better place than it was, not re-write whole files
for cosmetic nits.

Often these stylistic nits are marked "optional": if the submitter feels like
it, they could change it, but it's no big deal if not.

I'll very often have style comments on things like:

 - unnecessary comments that just describe the code
 - missing comments
 - variable, function naming
 - function size and decomposition
 - local customs

Many of these things can be a matter of opinion, so I try to bear in mind other
ways of thinking, up to a point. I'm never going to be happy seeing a ton of
CamelCase and Hungarian notation in code that doesn't have it already.

# Iterate

I haven't yet found a code review tool that's ideal at iteration: gerrit is
still pretty hopeless at tracking outstanding comment state. PRs in github are
better at displaying this, but have the fatal flaw that any history rewrite
means all context is lost.

Regardless, when I get a new version of the changes, I'll often review both the
incremental diff and the whole change, checking that:

 - my review comments have been acted upon and the fixes look good
 - the change as a whole still makes sense:
   - is the commit message still correct?
   - are there now unnecessary changes, due to follow-on fixes?
   - do the updates go far enough?

Long review cycles for a PR can be grueling, both for reviewers and the PR
owner. But in my opinion it's almost always worth the effort, especially for
complex changes: this code is
probably going to live a lot longer than you'd think, and be maintained by
people other than you.

Even worse, it's often work not given the respect it's due: PR owners can see it
as a combative process, and management can see it as overhead. I don't really
know what to do about that.

Pay it forward!
