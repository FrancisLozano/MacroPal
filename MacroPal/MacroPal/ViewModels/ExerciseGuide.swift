//
//  ExerciseGuide.swift
//  MacroPal
//

import Foundation

/// How to do an exercise and the usual ways it goes wrong, for the exercise screen's Overview
/// tab. General coaching cues written for this app, not copied from one source; a starting
/// point, not a substitute for a coach.
struct ExerciseGuide {
    struct Mistake: Hashable {
        /// What people do wrong.
        let mistake: String
        /// How to adjust it.
        let fix: String
    }

    let steps: [String]
    let mistakes: [Mistake]
}

enum ExerciseGuides {
    private static func guide(_ steps: [String], _ mistakes: [(String, String)]) -> ExerciseGuide {
        ExerciseGuide(steps: steps, mistakes: mistakes.map { ExerciseGuide.Mistake(mistake: $0.0, fix: $0.1) })
    }

    /// The guide for a starter exercise, nil for one the user created.
    static func guide(forName name: String) -> ExerciseGuide? {
        byName[name.lowercased()]
    }

    /// Keyed by lowercased name — matches `StarterExerciseCatalog`.
    private static let byName: [String: ExerciseGuide] = [
        // MARK: Chest
        "barbell bench press": guide([
            "Lie on the bench with your eyes under the bar and your feet flat on the floor.",
            "Grip the bar a little wider than your shoulders, squeeze your shoulder blades together and unrack it over your shoulders.",
            "Lower the bar under control to your lower chest, elbows about 45° from your body.",
            "Press it back up over your shoulders until your arms are straight.",
        ], [
            ("Elbows flared straight out to the sides.", "Tuck them to about 45°: it's easier on the shoulders and stronger."),
            ("Bouncing the bar off the chest.", "Touch lightly and pause for a moment before pressing."),
            ("Hips lifting off the bench.", "Keep your glutes down and drive through your feet instead."),
        ]),
        "incline barbell bench press": guide([
            "Set the bench to about 30–45° and sit with your eyes under the bar.",
            "Grip a little wider than your shoulders, pull your shoulder blades back and unrack.",
            "Lower the bar to your upper chest, just below the collarbone.",
            "Press up and slightly back so the bar finishes over your shoulders.",
        ], [
            ("Bench set too steep, turning it into a shoulder press.", "Keep the incline at 45° or lower."),
            ("Lowering the bar to the neck or mid-chest.", "Aim for the upper chest, just under the collarbone."),
            ("Losing the shoulder-blade squeeze as you tire.", "Reset between reps: shoulder blades back and down."),
        ]),
        "machine chest press": guide([
            "Set the seat so the handles line up with the middle of your chest.",
            "Sit back with your shoulder blades against the pad and your feet flat.",
            "Press the handles forward until your arms are straight, without locking out hard.",
            "Let them come back slowly until you feel a stretch across the chest.",
        ], [
            ("Seat too high or too low, so the shoulders take over.", "Line the handles up with mid-chest before the first rep."),
            ("Shoulders rolling forward off the pad as you press.", "Keep your back and shoulder blades on the pad the whole set."),
            ("Letting the stack slam between reps.", "Stop just before the plates touch, then press again."),
        ]),
        "dumbbell bench press": guide([
            "Sit with the dumbbells on your thighs, then lie back and bring them up over your chest.",
            "Start with your arms straight and palms facing forward or slightly in.",
            "Lower the dumbbells to the sides of your chest, elbows about 45° from your body.",
            "Press them back up and slightly together over your chest.",
        ], [
            ("Letting the dumbbells drift out wide at the bottom.", "Keep your forearms vertical, wrists over elbows."),
            ("Cutting the range short.", "Lower until you feel a stretch in the chest, then press."),
            ("Clanging the dumbbells together at the top.", "Stop just short of touching and keep tension on the chest."),
        ]),
        "incline dumbbell press": guide([
            "Set the bench to about 30–45°, sit back and bring the dumbbells up over your upper chest.",
            "Pull your shoulder blades back and down into the bench.",
            "Lower the dumbbells to the sides of your upper chest.",
            "Press them up until your arms are straight, without locking out hard.",
        ], [
            ("Bench too steep, so the shoulders do the work.", "Lower the incline to 30–45°."),
            ("Arching hard off the bench to move more weight.", "Keep your back gently arched and your hips down."),
            ("Dropping the weights fast on the way down.", "Take about two seconds to lower each rep."),
        ]),
        "cable chest fly": guide([
            "Set both pulleys at about shoulder height and take a handle in each hand.",
            "Step forward into a split stance with a slight bend in your elbows.",
            "Bring your hands together in front of your chest in a wide hugging arc.",
            "Let them return slowly until you feel a stretch across the chest.",
        ], [
            ("Bending the elbows more and more, turning it into a press.", "Keep the same slight elbow bend for the whole rep."),
            ("Letting the arms go too far back.", "Stop when your hands are in line with your chest."),
            ("Using body sway to move the weight.", "Brace your core and move only at the shoulders."),
        ]),
        "push-up": guide([
            "Start in a high plank with your hands just wider than your shoulders.",
            "Keep a straight line from head to heels and brace your core.",
            "Lower your chest toward the floor, elbows about 45° from your body.",
            "Push the floor away until your arms are straight.",
        ], [
            ("Hips sagging or piking up.", "Squeeze your glutes and brace like a plank."),
            ("Elbows flared straight out.", "Tuck them to about 45°."),
            ("Half reps.", "Go until your chest is about a fist from the floor; do them from your knees or an incline if needed."),
        ]),
        "chest dip": guide([
            "Hold the bars with straight arms and your shoulders pressed down.",
            "Lean your torso forward slightly and bend your knees behind you.",
            "Lower until your upper arms are about parallel to the floor.",
            "Press back up to straight arms.",
        ], [
            ("Going too deep and straining the front of the shoulder.", "Stop at about parallel."),
            ("Staying bolt upright, which shifts the work to the triceps.", "Lean forward a little to work the chest."),
            ("Shrugging the shoulders up to the ears.", "Keep your shoulders pushed down away from your ears."),
        ]),

        // MARK: Back
        "deadlift": guide([
            "Stand with your feet hip-width apart and the bar over the middle of your feet.",
            "Hinge down and grip the bar just outside your legs.",
            "Brace your core, flatten your back and pull the slack out of the bar.",
            "Push the floor away and stand up tall, keeping the bar close to your legs.",
            "Lower it the same way: hips back first, then bend the knees once it passes them.",
        ], [
            ("Rounding the lower back.", "Brace hard before each rep and keep your chest up; lower the weight until you can."),
            ("The bar drifting away from the body.", "Keep it touching your shins and thighs the whole way."),
            ("Leaning back at the top.", "Finish by squeezing your glutes, standing straight."),
        ]),
        "pull-up": guide([
            "Hang from the bar with your hands a little wider than your shoulders, palms facing away.",
            "Pull your shoulder blades down and back to start the movement.",
            "Pull until your chin is over the bar.",
            "Lower all the way to straight arms under control.",
        ], [
            ("Kicking or swinging to get up.", "Keep your legs still and core tight; use a band or the assisted machine if needed."),
            ("Half reps that stop short at the bottom.", "Straighten your arms fully between reps."),
            ("Craning the neck to get the chin over.", "Pull your chest toward the bar instead."),
        ]),
        "lat pulldown": guide([
            "Sit with your thighs under the pads and grip the bar a little wider than your shoulders.",
            "Lean back slightly and pull your shoulder blades down.",
            "Pull the bar to your upper chest, leading with your elbows.",
            "Let it rise until your arms are straight.",
        ], [
            ("Leaning far back and using body weight.", "Keep the lean small and steady."),
            ("Pulling the bar behind the neck.", "Always pull to the front, to the upper chest."),
            ("Pulling with the arms only.", "Think about driving your elbows down to your sides."),
        ]),
        "barbell row": guide([
            "Hold the bar with an overhand grip just wider than your shoulders.",
            "Hinge at the hips until your torso is about 45° or lower, back flat, knees soft.",
            "Row the bar to your lower ribs, squeezing your shoulder blades together.",
            "Lower it until your arms are straight.",
        ], [
            ("Standing more upright each rep.", "Hold the same hinge the whole set; lower the weight if you can't."),
            ("Jerking the weight with the hips.", "Keep your body still and let the back do the pulling."),
            ("Rounding the back.", "Brace and keep your chest up."),
        ]),
        "seated cable row": guide([
            "Sit with your feet on the platform, knees slightly bent, and hold the handle.",
            "Sit tall with your chest up and arms straight.",
            "Pull the handle to your stomach, squeezing your shoulder blades together.",
            "Let your arms straighten and your shoulder blades spread forward, then repeat.",
        ], [
            ("Rocking back and forth to move the weight.", "Keep your torso still and upright."),
            ("Shrugging as you pull.", "Keep your shoulders down and pull with the elbows."),
            ("Rounding the back at the front of the rep.", "Stay tall and let only the arms and shoulder blades reach."),
        ]),
        "one-arm dumbbell row": guide([
            "Put one knee and the same hand on a bench, back flat and parallel to the floor.",
            "Hold the dumbbell in the other hand with your arm hanging straight.",
            "Row it toward your hip, keeping your elbow close to your body.",
            "Lower it until your arm is straight.",
        ], [
            ("Twisting the torso to lift the weight.", "Keep your shoulders square to the floor."),
            ("Pulling to the chest instead of the hip.", "Drive the elbow back toward your hip."),
            ("Not lowering all the way.", "Let the arm straighten and the shoulder stretch each rep."),
        ]),
        "face pull": guide([
            "Set a rope on a cable at about face height and hold it with your thumbs toward you.",
            "Step back so your arms are straight and the weight is off the stack.",
            "Pull the rope toward your face, spreading the ends and driving your elbows high and back.",
            "Return slowly until your arms are straight.",
        ], [
            ("Going too heavy and leaning back.", "Use a light weight and stand still."),
            ("Elbows dropping low so it becomes a row.", "Keep your elbows at shoulder height or above."),
            ("Pulling to the chest.", "Aim the rope at your forehead or eyes."),
        ]),

        // MARK: Shoulders
        "overhead press": guide([
            "Stand with the bar resting on your front shoulders, hands just wider than your shoulders.",
            "Squeeze your glutes and brace your core.",
            "Press the bar straight up, moving your head back slightly to let it pass.",
            "Finish with the bar over the middle of your head and arms straight, then lower it to your shoulders.",
        ], [
            ("Leaning back into a big arch.", "Squeeze your glutes and keep your ribs down."),
            ("Pressing the bar forward around the face.", "Keep it close; move your head back, then forward under the bar."),
            ("Stopping short of full lockout.", "Finish with your arms straight and the bar over your head."),
        ]),
        "dumbbell shoulder press": guide([
            "Sit or stand with the dumbbells at shoulder height, palms forward.",
            "Brace your core and keep your back against the bench if seated.",
            "Press the dumbbells up until your arms are straight.",
            "Lower them back to shoulder height under control.",
        ], [
            ("Arching the lower back.", "Brace your core; use a bench with a back if needed."),
            ("Lowering only halfway.", "Bring the dumbbells down to about ear level."),
            ("Elbows flared fully to the sides.", "Bring them slightly forward, about 30° in front of your body."),
        ]),
        "lateral raise": guide([
            "Stand with a dumbbell in each hand at your sides, slight bend in the elbows.",
            "Raise your arms out to the sides, leading with your elbows.",
            "Stop when your arms are about level with your shoulders.",
            "Lower them slowly.",
        ], [
            ("Swinging the weights up with the body.", "Use lighter dumbbells and keep your torso still."),
            ("Shrugging the shoulders up.", "Keep your shoulders down and think of pushing the weights out, not up."),
            ("Going far above shoulder height.", "Stop at shoulder level."),
        ]),
        "rear delt fly": guide([
            "Hinge forward until your torso is nearly parallel to the floor, dumbbells hanging below you.",
            "Keep a slight bend in your elbows.",
            "Raise the dumbbells out to the sides until your arms are in line with your body.",
            "Lower them slowly.",
        ], [
            ("Squeezing the shoulder blades together, turning it into a row.", "Keep the shoulder blades still and move at the shoulder."),
            ("Standing up as you lift.", "Hold the hinged position the whole set."),
            ("Going too heavy.", "Use light weights; the rear delts are small."),
        ]),

        // MARK: Arms
        "barbell curl": guide([
            "Stand holding the bar with an underhand grip, hands shoulder-width apart.",
            "Keep your elbows at your sides.",
            "Curl the bar up toward your shoulders.",
            "Lower it until your arms are straight.",
        ], [
            ("Swinging the torso to lift the bar.", "Stand still and lower the weight if you have to swing."),
            ("Elbows drifting forward.", "Keep them pinned at your sides."),
            ("Dropping the bar fast.", "Take about two seconds to lower it."),
        ]),
        "dumbbell curl": guide([
            "Stand with a dumbbell in each hand, palms facing forward.",
            "Keep your elbows at your sides.",
            "Curl the dumbbells up toward your shoulders, together or one at a time.",
            "Lower them until your arms are straight.",
        ], [
            ("Using momentum from the hips.", "Keep your body still; lighter weights, stricter reps."),
            ("Elbows moving forward at the top.", "Keep them at your sides the whole rep."),
            ("Short reps.", "Straighten your arms at the bottom each time."),
        ]),
        "hammer curl": guide([
            "Stand with a dumbbell in each hand, palms facing your body.",
            "Keep your elbows at your sides.",
            "Curl the dumbbells up, keeping your palms facing in.",
            "Lower them until your arms are straight.",
        ], [
            ("Turning the palms up as you lift.", "Keep a neutral grip, thumbs up, like holding a hammer."),
            ("Swinging the dumbbells.", "Keep your torso still and your elbows at your sides."),
            ("Going too heavy for a full range.", "Lower the weight until you can curl all the way up."),
        ]),
        "triceps pushdown": guide([
            "Face a high cable with a bar or rope and grip it with your elbows at your sides.",
            "Lean forward very slightly.",
            "Push the handle down until your arms are straight.",
            "Let it rise until your forearms are about parallel to the floor.",
        ], [
            ("Elbows flaring out or moving forward.", "Keep them pinned at your sides."),
            ("Leaning over the bar and pushing with body weight.", "Stand nearly upright and use only the arms."),
            ("Letting the handle rise too high.", "Stop when your forearms are about level."),
        ]),
        "skull crusher": guide([
            "Lie on a bench holding the bar over your chest with straight arms.",
            "Tilt your arms back slightly toward your head.",
            "Bend only at the elbows to lower the bar toward your forehead.",
            "Straighten your arms to press it back up.",
        ], [
            ("Elbows flaring out.", "Keep them pointing toward the ceiling, about shoulder-width."),
            ("Moving the upper arms, turning it into a press.", "Keep the upper arms still; only the elbows bend."),
            ("Going too heavy.", "Use a weight you can lower slowly to the forehead."),
        ]),
        "overhead triceps extension": guide([
            "Hold one dumbbell with both hands above your head, arms straight.",
            "Keep your elbows pointing forward, close to your head.",
            "Lower the dumbbell behind your head by bending your elbows.",
            "Straighten your arms to lift it back up.",
        ], [
            ("Elbows flaring wide.", "Keep them narrow, near your ears."),
            ("Arching the lower back.", "Brace your core; sit on a bench with a back if needed."),
            ("Short reps.", "Lower until you feel a stretch in the back of the arm."),
        ]),

        // MARK: Legs
        "back squat": guide([
            "Set the bar on your upper back, not your neck, and stand with feet about shoulder-width apart.",
            "Brace your core and take a breath.",
            "Sit down and back, pushing your knees out over your toes.",
            "Go until your hips are at least level with your knees, then drive back up.",
        ], [
            ("Knees caving in.", "Push your knees out in line with your toes."),
            ("Heels lifting.", "Keep your weight over the middle of your feet; widen your stance if needed."),
            ("Squatting too shallow.", "Lower the weight and aim for thighs at least parallel."),
        ]),
        "front squat": guide([
            "Rest the bar on the front of your shoulders with your elbows high.",
            "Stand with feet about shoulder-width apart and brace your core.",
            "Squat straight down, keeping your torso upright.",
            "Drive back up, keeping your elbows high.",
        ], [
            ("Elbows dropping, so the bar rolls forward.", "Drive your elbows up throughout the rep."),
            ("Leaning forward.", "Stay upright; lighten the load if needed."),
            ("Holding the bar in the hands instead of on the shoulders.", "Let it sit on the shoulders; fingertips only guide it."),
        ]),
        "romanian deadlift": guide([
            "Stand holding the bar at your thighs, feet hip-width apart, knees soft.",
            "Push your hips back and let the bar slide down your thighs.",
            "Lower until you feel a strong stretch in your hamstrings, usually just below the knees.",
            "Drive your hips forward to stand back up.",
        ], [
            ("Bending the knees too much, turning it into a squat.", "Keep a slight, fixed knee bend."),
            ("Rounding the back to reach lower.", "Stop where your back stays flat."),
            ("The bar drifting away from the legs.", "Keep it touching your thighs the whole way."),
        ]),
        "leg press": guide([
            "Sit with your back flat against the pad and your feet shoulder-width on the platform.",
            "Release the safeties and bend your knees to lower the platform.",
            "Go until your knees are at about 90°.",
            "Press back up without locking your knees.",
        ], [
            ("Lower back lifting off the pad at the bottom.", "Stop the rep before your hips curl up."),
            ("Locking the knees hard at the top.", "Stop just short of full lockout."),
            ("Knees caving in.", "Keep them in line with your toes."),
        ]),
        "walking lunge": guide([
            "Stand tall holding a dumbbell in each hand.",
            "Step forward and lower until both knees are at about 90°.",
            "Push off the front foot and bring the back foot forward into the next step.",
            "Keep going, alternating legs.",
        ], [
            ("Front knee caving in.", "Keep it over your toes."),
            ("Steps too short, so the knee goes far past the toes.", "Take longer steps."),
            ("Leaning the torso forward.", "Stay tall and look ahead."),
        ]),
        "bulgarian split squat": guide([
            "Stand in front of a bench and rest the top of your back foot on it.",
            "Hold a dumbbell in each hand and hop the front foot forward.",
            "Lower until your front thigh is about parallel to the floor.",
            "Drive through the front foot to stand back up.",
        ], [
            ("Front foot too close to the bench.", "Step it far enough forward that your knee stays roughly over your foot."),
            ("Pushing off the back leg.", "Keep the weight on the front leg; the back foot is just for balance."),
            ("Wobbling side to side.", "Slow down and look at a point in front of you."),
        ]),
        "leg extension": guide([
            "Sit with your back against the pad and the ankle pad just above your feet.",
            "Line your knees up with the machine's pivot.",
            "Straighten your legs to lift the pad.",
            "Lower it slowly.",
        ], [
            ("Kicking the weight up fast.", "Lift smoothly and pause at the top."),
            ("Lifting the hips off the seat.", "Hold the handles and stay seated."),
            ("Letting the weight stack slam down.", "Lower it under control."),
        ]),
        "leg curl": guide([
            "Lie or sit on the machine with the pad just above your heels.",
            "Line your knees up with the machine's pivot.",
            "Curl your heels toward your glutes.",
            "Lower them slowly.",
        ], [
            ("Hips lifting off the pad.", "Keep your hips pressed down."),
            ("Short reps.", "Curl all the way and straighten fully."),
            ("Dropping the weight fast.", "Take about two seconds to lower."),
        ]),
        "hip thrust": guide([
            "Sit with your upper back against a bench and a padded bar over your hips.",
            "Plant your feet flat, about hip-width, so your shins are vertical at the top.",
            "Drive through your heels to lift your hips until your body is flat from shoulders to knees.",
            "Squeeze your glutes at the top, then lower.",
        ], [
            ("Arching the lower back at the top.", "Tuck your chin and ribs; stop when your hips are level."),
            ("Feet too far forward or back.", "Set them so your shins are vertical at the top."),
            ("Rushing the top.", "Pause and squeeze your glutes for a second."),
        ]),
        "standing calf raise": guide([
            "Stand with the balls of your feet on a step or the machine's platform.",
            "Let your heels drop below the step for a stretch.",
            "Rise up onto your toes as high as you can.",
            "Lower slowly back to the stretch.",
        ], [
            ("Bouncing at the bottom.", "Pause for a second in the stretch."),
            ("Short reps.", "Go from a full stretch to fully on your toes."),
            ("Bending the knees to help.", "Keep your legs straight."),
        ]),

        // MARK: Core
        "plank": guide([
            "Rest on your forearms with your elbows under your shoulders.",
            "Straighten your legs behind you, on your toes.",
            "Make a straight line from head to heels and brace your core.",
            "Hold it, breathing steadily.",
        ], [
            ("Hips sagging.", "Squeeze your glutes and pull your belly button in."),
            ("Hips piked high.", "Lower them until your body is straight."),
            ("Holding your breath.", "Breathe slowly the whole time."),
        ]),
        "hanging leg raise": guide([
            "Hang from a bar with straight arms.",
            "Brace your core and keep your legs together.",
            "Raise your legs until they're level with your hips or higher, curling your pelvis up.",
            "Lower them slowly without swinging.",
        ], [
            ("Swinging to get the legs up.", "Pause at the bottom until you're still."),
            ("Lifting with the hip flexors only.", "Curl your pelvis up at the top to work the abs."),
            ("Too hard at first.", "Start with bent knees."),
        ]),
        "cable crunch": guide([
            "Kneel facing a high cable, holding a rope beside your head.",
            "Keep your hips still, sitting back slightly.",
            "Crunch down, bringing your elbows toward your thighs by rounding your spine.",
            "Return slowly until your back is straight.",
        ], [
            ("Pulling with the arms.", "Keep your hands fixed by your head; the abs do the work."),
            ("Sitting back onto the heels, using the hips.", "Keep your hips still and curl your spine."),
            ("Going too heavy.", "Use a weight you can crunch slowly."),
        ]),
        "ab wheel rollout": guide([
            "Kneel with the wheel in front of your knees, hands on the handles.",
            "Brace your core and tuck your pelvis slightly.",
            "Roll the wheel forward as far as you can without your back sagging.",
            "Pull it back in using your abs.",
        ], [
            ("Lower back sagging.", "Only roll out as far as you can keep your back flat."),
            ("Hips staying high and moving first.", "Let your hips and shoulders move forward together."),
            ("Rolling too far too soon.", "Start with short rollouts, or roll toward a wall."),
        ]),
        "single-arm triceps extension": guide([
            "Sit tall on a bench and hold one dumbbell straight overhead.",
            "Keep your upper arm next to your head, elbow pointing up.",
            "Lower the dumbbell behind your head by bending only the elbow.",
            "Straighten the arm back up and squeeze the triceps at the top.",
        ], [
            ("Elbow flaring out to the side.", "Keep it pointing at the ceiling; go lighter if it drifts."),
            ("Arching the lower back to push the weight up.", "Brace your abs and keep your ribs down."),
            ("Stopping short of a full stretch.", "Lower until the dumbbell is behind your neck, then press."),
        ]),
        "cable lateral raise": guide([
            "Set a handle on the lowest pulley and stand side-on to the stack.",
            "Hold the handle in the far hand, in front of your thigh, with a slight bend in the elbow.",
            "Raise the arm out to the side until it's level with your shoulder.",
            "Lower it slowly, keeping tension on the cable at the bottom.",
        ], [
            ("Shrugging the shoulder up as the arm rises.", "Keep the shoulder down, away from your ear."),
            ("Leaning away and swinging.", "Stand tall and use a weight you can raise under control."),
            ("Raising the arm above shoulder height.", "Stop at shoulder level; the traps take over above it."),
        ]),
        "machine shoulder press": guide([
            "Set the seat so the handles start at about shoulder height.",
            "Sit with your back against the pad and grip the handles.",
            "Press up until your arms are straight, without locking out hard.",
            "Lower until your hands are back at shoulder height.",
        ], [
            ("Seat too low, so the press starts below your shoulders.", "Raise the seat until the handles line up with your shoulders."),
            ("Arching off the back pad.", "Keep your lower back on the pad and brace your abs."),
            ("Letting the stack drop between reps.", "Lower under control and stop before the plates touch."),
        ]),
        "chest-supported dumbbell row": guide([
            "Set an incline bench to about 30–45° and lie face down with your chest on the pad.",
            "Let the dumbbells hang straight down, palms facing in.",
            "Row them up toward your hips, squeezing your shoulder blades together.",
            "Lower them slowly until your arms are straight again.",
        ], [
            ("Lifting the chest off the pad to heave the weight.", "Keep your chest on the pad the whole set."),
            ("Pulling with the arms and shrugging.", "Start each rep by drawing the shoulder blades back."),
            ("Cutting the stretch short at the bottom.", "Let the arms hang all the way down between reps."),
        ]),
        "close-grip row": guide([
            "Attach a close-grip (V) handle to the low pulley and sit with your feet on the platform.",
            "Sit tall with a slight bend in your knees and your arms straight in front of you.",
            "Pull the handle to your lower ribs, elbows close to your sides.",
            "Let it go forward slowly until your arms are straight, without rounding your back.",
        ], [
            ("Rocking the torso back and forth to move the weight.", "Keep your torso still; only the arms and shoulder blades move."),
            ("Rounding the lower back as the handle goes forward.", "Keep your chest up and reach only as far as your back stays flat."),
            ("Elbows flaring out.", "Keep them close to your sides so the lats do the work."),
        ]),
        "single-arm cable rear delt fly": guide([
            "Set a handle on a pulley at about shoulder height and stand facing the stack.",
            "Hold the handle in the opposite hand with a slight bend in the elbow.",
            "Pull the arm out and back across your body until it's in line with your shoulder.",
            "Return slowly until the arm is in front of you again.",
        ], [
            ("Turning the torso to swing the weight.", "Keep your chest facing the stack and your hips still."),
            ("Bending the elbow into a row.", "Keep the same slight bend all the way through."),
            ("Going too heavy for the rear delt.", "Use a light weight and pause at the back of each rep."),
        ]),
        "preacher curl": guide([
            "Sit at the preacher bench with the backs of your arms flat on the pad.",
            "Hold the bar with an underhand grip, shoulder-width apart.",
            "Curl the bar up until your forearms are nearly vertical.",
            "Lower it slowly until your arms are almost straight.",
        ], [
            ("Lifting the elbows off the pad.", "Keep the backs of your arms on the pad the whole time."),
            ("Dropping the weight at the bottom.", "Lower under control; the bottom is where the strain is highest."),
            ("Stopping halfway down.", "Go until your arms are nearly straight for the full range."),
        ]),
        "seated leg curl": guide([
            "Set the back pad so your knees line up with the machine's pivot.",
            "Put the lower pad just above your heels and lock the thigh pad down.",
            "Curl your heels down and back as far as they'll go.",
            "Let the pad come back up slowly until your legs are nearly straight.",
        ], [
            ("Knees out of line with the pivot.", "Adjust the back pad before your first set."),
            ("Lifting your hips off the seat.", "Keep the thigh pad snug and your back against the pad."),
            ("Letting the weight snap back up.", "Control the return; it's half the work."),
        ]),
        "floor back extension": guide([
            "Lie face down on the floor with your arms by your sides or out in front of you.",
            "Keep your legs straight and your neck in line with your spine.",
            "Lift your chest (and your legs, for the full version) a few inches off the floor.",
            "Hold for a moment, then lower slowly.",
        ], [
            ("Throwing the head back to get higher.", "Look at the floor just in front of you."),
            ("Jerking up with momentum.", "Rise slowly and pause at the top."),
            ("Lifting higher than the lower back is comfortable with.", "A few inches is enough; stop before any pinch."),
        ]),
        "adductor machine": guide([
            "Sit with your back against the pad and set the leg pads as wide as is comfortable.",
            "Put the insides of your knees against the pads.",
            "Squeeze your legs together until the pads meet.",
            "Let them open slowly back to the start.",
        ], [
            ("Starting wider than your hips allow.", "Pick a start width you can control and widen it over time."),
            ("Letting the pads fly back open.", "Open them slowly and stop before the stack touches."),
            ("Leaning forward to help.", "Keep your back on the pad and your chest up."),
        ]),
        "machine ab crunch": guide([
            "Set the seat so the chest pad or handles sit at the top of your chest.",
            "Hook your feet under the rollers if the machine has them, and grip the handles.",
            "Curl your chest toward your hips, rounding your upper back.",
            "Return slowly until your abs are stretched, without letting the stack rest.",
        ], [
            ("Pulling with the arms instead of crunching.", "Keep your arms still and think about ribs to hips."),
            ("Bending at the hips instead of the spine.", "Round your upper back; the hips stay put."),
            ("Too much weight and a short range.", "Use a load you can take through the full crunch."),
        ]),
    ]
}
