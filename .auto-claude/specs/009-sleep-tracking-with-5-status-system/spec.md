# Sleep Tracking with 5-Status System

Sleep logging with 5-status tracking (very poor, poor, average, good, excellent), duration input, wake time prompts, and correlation with other health metrics. Automatic morning prompt to log previous night's sleep.

## Rationale
Unique 5-status sleep tracking is a differentiator. Competitors either don't track sleep or have limited options. Sleep affects metabolism, energy expenditure, and food choices - showing correlations provides value competitors miss. Addresses user goal of complete health picture.

## User Stories
- As a user, I want to track my sleep quality so that I can see how it affects my health
- As a health-conscious person, I want morning prompts so that I don't forget to log sleep

## Acceptance Criteria
- [ ] Morning prompt appears after 6 AM to log previous night's sleep
- [ ] Users can log sleep duration (hours:minutes)
- [ ] 5-status quality rating with visual feedback
- [ ] 02:00 boundary logic correctly assigns sleep to previous day
- [ ] Skip option available (max 3 times before forced entry)
- [ ] Sleep trends visible on weekly/monthly view
- [ ] Sleep data correlates with energy and food logging patterns
