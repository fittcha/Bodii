# Body Composition Tracking with BMR/TDEE

Complete body composition logging system including height, weight, body fat percentage, muscle mass, with automatic BMR (Mifflin-St Jeor) and TDEE calculations. Visualize changes over time with Swift Charts graphs showing trends and goal progress.

## Rationale
Core differentiator: unified body composition + metabolic tracking that competitors lack. Addresses user pain point of 'hard to see correlations between body composition changes and lifestyle factors'. Better than InBody's unreliable app with 3-22% body fat variation complaints.

## User Stories
- As a fitness enthusiast, I want to track my body fat and muscle mass changes so that I can see my progress
- As a dieter, I want to know my BMR/TDEE so that I can plan my calorie intake accurately
- As a goal-oriented user, I want to visualize my body composition trends so that I stay motivated

## Acceptance Criteria
- [ ] Users can input height, weight, body fat %, muscle mass with validation
- [ ] BMR calculated automatically using Mifflin-St Jeor formula
- [ ] TDEE calculated based on activity level multiplier
- [ ] MetabolismSnapshot saved with each body record for historical tracking
- [ ] Swift Charts displays weight/body fat trends over 7/30/90 days
- [ ] Dashboard shows current BMR/TDEE alongside daily intake/expenditure
- [ ] Performance: queries complete in under 0.5 seconds
