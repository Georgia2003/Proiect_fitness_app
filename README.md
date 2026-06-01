

The application is a Gamified Fitness & Health Tracker where user biometrics control a central animated avatar, and local logs are synchronized reactively.

### 1. ARCHITECTURE & TECH STACK REQUIREMENTS
- State Management: Flutter BLoC (`flutter_bloc`)
- Local Database: Drift (`drift`, `drift_dev`) with Stream queries for reactive UI.
- Networking: Dio (`dio`) wrapped in a Repository that prefers local cache and syncs in the background.
- UI: Modern, Dark Mode High-Contrast Gym/Cyberpunk Theme (Background: #0B0F19, Accent: #10B981, Indigo: #6366F1).
- Animation Placeholder: Since we will integrate Rive later, create a dedicated custom widget `GymAvatar` that uses CustomPainter or Implicit Animations to simulate an avatar changing states (Idle, Exercising, Resting) based on the current app state.

### 2. DETAILED APP STRUCTURE (BOTTOM NAVIGATION BAR)

#### Slide/Tab 1: Profile & Biometrics
- Fields: Name, Age, Gender, Height (cm), Weight (kg), Body Fat Percentage (%).
- Computation: Implement the Mifflin-St Jeor Equation directly in Dart to calculate BMR and Daily Caloric/Macronutrient targets based on weight:
  - Calories Target = BMR * 1.2 (Sedentary baseline)
  - Protein Target = 2.0g * Weight (kg)
  - Carbs Target = 4.0g * Weight (kg)
  - Fats Target = 1.0g * Weight (kg)
- Features: Editable fields that instantly update the SQLite database via Drift and trigger a BLoC state change to recalculate macro targets across the app.

#### Slide/Tab 2: Interactive Workout Module
- Features: A list of predefined exercises (Push-ups, Squats, Pull-ups).
- Mechanics: Selecting an exercise changes the `GymAvatar` state to 'Exercising'.
- Elements: 
  - Dynamic Timer/Chronometer for set execution and rest intervals.
  - Log sets, reps, and weights directly into the Drift DB.
  - When resting, `GymAvatar` state changes to 'Resting'.

#### Slide/Tab 3: Nutrition Tracker & Analytics
- Features: Log Daily Intake (Food Name, Calories, Protein, Carbs, Fats).
- UI Component: A beautifully rendered CustomPaint or layout-based progress indicator showing current daily intake VS computed ideal targets from Tab 1.
- Statistical Graph: A horizontal or vertical historical chart showing adherence over the last 7 days.

### 3. DATABASE SCHEMA (DRIFT)
Generate the Drift table definitions for:
- `Users` (id, name, age, gender, height, weight, bodyFat, isSynced)
- `Workouts` (id, exerciseName, sets, reps, weight, timestamp, isSynced)
- `Nutrition` (id, foodName, calories, protein, carbs, fats, date, isSynced)


