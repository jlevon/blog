---
title: "Github Pull Requests"
date: 2021-02-06T13:46:53Z
---

[Stefan Hajnoczi](http://blog.vmsplice.net/) recently [posted about clean commit
history](http://blog.vmsplice.net/2021/02/keeping-clean-git-commit-history.html).

It's a controversial viewpoint that not everyone agrees with - there is a
sizable population in favour of "never rewrite history". For me, though, the
points he makes there are totally correct: each commit should be a logical
change, `main` (neé `master`) should stay green, and CI should pass at every
single point in `main`'s history. More than just CI though: regardless of
whether it passes CI, the `main` branch should be of good quality at all times,
if you want to avoid the [Quality Death
Spiral](https://illumos.org/docs/contributing/qds/).

Unfortunately, Github pull requests make this model a little difficult for a few
reasons:

## You can't ever rebase a PR undergoing review

It's important that a non-draft PR is never rebased, or re-written in any way.
Why? Well, aside from making it difficult for a reviewer to see what's changed
since last looking, if you rebase, the commits previously on the PR disappear
off into [reflog
hyperspace](https://github.blog/2015-06-08-how-to-undo-almost-anything-with-git/).

The `View Changes` button on review comments is attached to that particular
commit hash, which is no longer in the history for that branch, and you get the
dreaded:

```
We went looking everywhere, but couldn’t find those commits.
```

Note that if your PR is still a draft, you're fine to edit the history whichever
way you like: in fact, it's often useful for review purposes to have multiple
commits even at the start of a PR review before you move it from draft. Up to you.

The only other safe time to rebase is on final approach. At that point,
presuming you are keeping to the "single `main` commit per PR" approach (see
below), you'll be wanting to squash the entire branch history into a single
commit to `main`. For this, I usually use
[prr](https://github.com/joyent/prr): it's handy for picking up `Reviewed-by`
automatically, and merging commit comments together for final editing.

## Github CI only runs on branch tips

You probably don't want to have a PR where you're going to merge more than
one commit into main. This is because CI only runs on the top-level commit: if
an ancestor commit breaks the build, you'll never know. Stefan mentions using
`git rebase --exec` for checking commits in a stack, which indeed works great,
but unless you're running exactly the same CI that's running under Github
Actions, you can't rely on it.

If that's the case, what if you have one or more changes that depend on another?
This is where "stacked PRs" come in, and they're a bit of a pain...

## Stacked PRs are cumbersome

[Gerrit](https://www.gerritcodereview.com/) has a really useful model for
reviewing stacks of changes: instead of the full history, each "patchset"
corresponds to the single logical change Stefan talks about above. Every time
you push to Gerrit, you're supposed to have collapsed and rebased additional
changes into single commits corresponding to each Gerrit CR.  The model has some
disadvantages as well (in particular, it's a bit of a pain to keep a full
history locally), but the Gerrit review UI doesn't suffer from the rebasing
issues Github does[^1].

Presuming - as there is no CI available - [gerrithub](https://gerrithub.io) is a
non-starter, the only option available on Github is to use multiple PRs. This is
better than it used to be, but is still a little painful.

Essentially, a stacked PR is one that's opened not against the `main` branch,
but against another PR branch. Say we have changes `A` and `B`, where `B` is
dependent on `A`. You'd create a local branch with `A`, then push it to Github
and open a PR. You'd have another local branch with `A` and `B`, then push
*that* branch to Github and open a *separate* PR.

Now we need to make the `B` PR be based against the `A` PR. You can do this via
the web UI by clicking `Edit`, though there is annoying bug here: it doesn't
reset the title and description. You can use `gh pr create --base ...` to avoid
this problem.

Now, in the second PR, you'll just see the commit for `B`.  Each PR can be
reviewed separately, and each PR gets its own CI run.

You also might want to merge additional changes up the stack. Let's say that you
have commit `A2` on the `A` PR, that you want in PR `B` and `C`: the best - if
rather tedious - way to do this, is to merge `A` into `B`, then `B` into `C`.
That's a lot of merge commits, but remember we're squashing a PR every time
before merging a PR to `main`.

You'll see on the web recommendations to "merge downwards": you wait for commit
approval for the whole stack, then merge the top PR (`B`) into the PR underneath
it (`A`), and so on, until you merge to `main`.

I don't think that's necessary these days[^2]. Instead, when you have approval for
the base PR - and logically, it will make sense that is reviewed first - you can
merge it to `main`. Github will then offer to delete the PR branch. If you do
this, the stacked PR gets automatically reset such that its merge base is now
`main` !

There is an annoying thing here though: because of that squash during the merge
to `main`, `git`, and Github, needs you to merge `main` back into the commit
history of the PR that just changed bases. If you already merged the parent PR,
you can always do `git merge -Xours master` to fix this, since there shouldn't
be any actual diff difference between the PR branch diffs as a whole, and what
was merged to master. Or, if you didn't merge in the parent PR, you'll need a
normal `git merge master`.

Another bug (as far as I'm concerned) is that if you ask for review on a stacked
PR, it doesn't get tagged with "Review required", since, technically, you could
merge the PR into its parent without approval. And there is no "Review
requested" tag.

I would love all this to have some tooling: something that lets me do
everything on my local stacked branches, automate merges up, keep track of
dependencies, and updating the branches in Github. But I haven't been able to
find anything that can do it.

[2022-05-12 update]: I just came across [spr](https://github.com/ejoffe/spr)
which is so far proving excellent in solving some of these problems. I love it!

[^1]: Gerrit uses
[Change-ID](https://gerrit-review.googlesource.com/Documentation/user-changeid.html)
embedded in the commit message to map commits onto CRs. It's clumsy but
effective.

[^2]: I think it dates from before Github automatically reset a PR when its
merge base was deleted
