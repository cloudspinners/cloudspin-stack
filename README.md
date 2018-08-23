# Cloudspin::Stack

This Ruby library is a prototype for an infrastructure project delivery framework. It is intended as a basis for exploring project structures, conventions, and functionality, but is not currently in a stable state.

Feel free to copy and use this, but be prepared to extend and modify it in order to make it useful for your own project. There isn't likely to be a clean path to upgrade your projects as this thing evolves - my assumption is that nobody else is directly depending on this code or the gems I've published from it.


## What's here

This project creates a ruby gem, which has some classes that can be used to manage instances of infrastructure stacks. These classes can be called used in rspec-based tests. There is also a command line tool included in the gem (`stack`), which can be used to manage stack instances.

A separate gem, [cloudspin-stack-rake](https://github.com/cloudspinners/cloudspin-stack-rake), can be used to create rake tasks that use the classes here to manage stacks.

The classes and tools in this gem are meant to be primitives. They shouldn't dictate details of how to organise and configure infrastructure and environments, although I've designed them to support patterns that I have in mind, so it's possible some of this has leaked into them.


## Examples

I'm using [spin-stack-network](https://github.com/cloudspinners/spin-stack-network) as an example of an infrastructure stack project to make use of this framework. I may add other projects in the future as the tool is developed.


# Concepts

## What's the point of this?

Currently, most people and teams managing infrastructure with tools such as Terraform, CloudFormation, etc. define their own project structures, and write their own wrapper scripts to run that tool and associated tasks. Essentially, each project is a unique snowflake.

The goal for cloudspin is to evolve a common structure and build tooling for infrastructure projects, focused on the lifecycle of "[stacks](http://infrastructure-as-code.com/patterns/2018/03/28/defining-stacks.html)" - infrastructure elements provisioned on dynamic infrastructure such as IaaS clouds.

Our hypothesis is that, with a common project structure and tooling:

- Teams will spend less time building and maintaining snowflake build systems,
- New team members can more quickly get up to speed when joining an infrastructure project,
- People can create and share tools and scripts that work with the common structure, creating an ecosystem,
- People can create and share infrastructure code for running various software and services, creating a community library.


## Philosophy

- [Convention over configuration](https://en.wikipedia.org/wiki/Convention_over_configuration).
-- The tool should discover elements of the project based on folder structure
-- A given configuration value should be set in a single place
-- Implies a highly "[opinionated](https://medium.com/@stueccles/the-rise-of-opinionated-software-ca1ba0140d5b)" approach
- Encourage good agile engineering practices for the infrastructure code
-- Writing and running tests should be a natural thing
-- Building and using [infrastructure pipelines](http://infrastructure-as-code.com/book/2017/08/02/environment-pipeline.html) should be a natural thing
- Support evolutionary architecture
-- Loose coupling of infrastructure elements
- Empower developers / users of infrastructure


# Instructions

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cloudspin-stack'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cloudspin-stack


## Documentation


### Stack Definition

A *stack definition* is a single infrastructure code project, i.e. a Terraform project (but could be implemented for CloudFormation, ARM, or other tools in the future).

### Stack Instance

A *stack instance* is an instance of the stack running on your infrastructure platform (I have used it for AWS so far, but it should work for other cloud platforms without much modification).

Operations on the stack include:

- up: create or update an instance of the stack, from a defintion
- down: destroy an instance of the stack

Each of these operations can be *planned*, which prints the changes that will be applied, without actually applying them.


## Usage: Ruby API

TODO: Write stuff.


## Usage: Command line tool

Create or update an instance of the stack defined in `TERRAFORM_FOLDER`, using the identifier `STACKNAME` to distinguish it from other instances of the stack:

```bash
stack up STACKNAME -t TERRAFORM_FOLDER
```

Destroy the stack instance:

```bash
stack down STACKNAME -t TERRAFORM_FOLDER
```

Each of these commands can take the `--dry` and/or `--plan` argument. 

`--dry` prints out the terraform command to be run, but doesn't do anything. So this doesn't even need AWS credentials to work.

`--plan` prints out the changes that will be made to the existing stack instance, if any. This does need AWS credentials.


## Configuration

The classes don't many assumptions about how to configure your stack projects. The classes themselves are very primitive: you'll pass in whatever parameters and resources you need, and then use those in your project files, generally as terraform variables.

The stack command line tool, and rake tasks, tests, and your own stuff will tend to put more conventions around parameters and resources.

Resources are essentially the same as parameters, but are assumed to relate to other infrastructure, e.g. things you'll need to integrate with, cloud provider credentials, etc.

All this needs more documentation and elaboration. For now, you can peruse the code, especially for the example project(s) mentioned above, and hopefully figure stuff out.


# Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/cloudspin-stack.


# Credits

This project makes extensive use of ideas and code from Toby Clemson and Jimmy Thompson, particularly [infrablocks](https://github.com/infrablocks). I've also benefited from feedback on implementation concepts from Vincenzo Fabrizi, and other [ThoughtWorkers](https://thoughtworks.com).

