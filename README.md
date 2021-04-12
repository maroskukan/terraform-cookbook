# Terraform Cookbook

- [Terraform Cookbook](#terraform-cookbook)
  - [Introduction](#introduction)
    - [Infrastructure as Code](#infrastructure-as-code)
    - [Imperative vs Declarative](#imperative-vs-declarative)

## Introduction

Terraform is tool developed by Hashicorp which is used for automated deployment of infrastructure across multiple providers in public and private cloud. It is a must have tool in order to fully benefit from Infrastructure as Code concepts.

### Infrastructure as Code

Infrastructure as Code (IaC) is to provision an infrastructure through use of software to achieve consistent and predictable environment.

There are some principles of IaC such as:
- Infrastructure is defined as code (yaml, json, hashicorp dsl)
- Code is stored in VCS
- Infrastructure definition can be imperative or declarative (prefered way)
- Deployment is idempotent and consistent
- Deployment can use push or pull model

The IaC brings number of benefits to the table such as:
- Automated deployment
- Consistent environments
- Repeatable process
- Reusable components
- Documented architecture

### Imperative vs Declarative

Infrastructure defined in imperative (procedural) way would mean you need to specify each configuration item as well as the order in which these items need to be applied to get desired outcome.

On the other hand, infrastructure defined in declarative way you only define the desired outcome, leaving implementation details up to software.






