# ATOM Policy Inventory - Project Memory

> **Purpose**: Long-term memory for ATOM policy inventory analysis project.

## 📋 Project Overview

**Start Date:** 2025-09-10
**Status:** Initial Setup
**Goal:** *To be defined based on project context*

### 🔗 Project Context & References
in this project, I wanna lay out all the active policies used in the atom event(decision platform decplat event which guardrail our login risk);

Thie query below is the way to pull real time active decplat atom event policies, their decision action and detection criteria etc. for your reference;


select distinct policy_name, policy_created_at, policy_outcome, policy_created_by, policy_criteria
from chime.decision_platform.policies
where 1=1

and event_name in ('atom_event')
and policy_status='active'
order by 1
;



### 🎯 Project Objectives
help us understand # of active policies and what they are meant to do and if there's any ambiguirty there and if some could be enhenced/retired/revamped etc.





*This memory file is ready for project context and detailed analysis information to be provided.*
