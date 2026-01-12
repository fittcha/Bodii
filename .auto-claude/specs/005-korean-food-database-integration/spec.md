# Korean Food Database Integration

Integrate Korean Food & Drug Administration (식약처) food nutrition database API as primary source, with USDA FoodData Central as fallback for international foods. Prioritize Korean dishes (kimchi jjigae, bibimbap, tteokbokki) that are poorly covered by competitors.

## Rationale
MAJOR DIFFERENTIATOR: No competitor prioritizes Korean food data. Cronometer and others are US-centric, YAZIO has inaccurate data. Korean users struggle with existing apps. Uses verified government databases only - no user-submitted data that causes accuracy issues in MyFitnessPal and YAZIO.

## User Stories
- As a Korean user, I want to find accurate nutrition data for Korean dishes so that I can track my meals properly
- As a user, I want accurate food data from verified sources so that my calorie tracking is reliable

## Acceptance Criteria
- [ ] 식약처 API integrated as primary food search source
- [ ] USDA API integrated as fallback for non-Korean foods
- [ ] Search returns Korean foods first, then international
- [ ] Food entity stores calories, protein, carbs, fat, sodium per serving
- [ ] Users can adjust serving size with automatic recalculation
- [ ] Recent foods cached locally for offline access
- [ ] Error handling for API failures with graceful fallback
