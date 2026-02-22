package com.example.app;

import android.os.Bundle;
import androidx.appcompat.app.AppCompatActivity;

/**
 * MainActivity – entry point for the sovereign-pipeline skeleton app.
 *
 * <p>Replace this class with your application logic.  See the inline comments
 * for common customisation points.</p>
 *
 * <p><b>Package / class rename:</b> when you change the {@code package}
 * attribute in AndroidManifest.xml and the {@code applicationId} in
 * app/build.gradle, also update this file's {@code package} declaration and
 * move the file to the matching directory path.</p>
 */
public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // Replace R.layout.activity_main with your own layout resource.
        setContentView(R.layout.activity_main);

        // ── Add your initialisation logic here ────────────────────────────────
        // Example: initialise a ViewModel, set up navigation, etc.
    }
}
