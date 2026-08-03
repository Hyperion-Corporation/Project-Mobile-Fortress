package com.example.gametemplate.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import com.example.gametemplate.R

/**
 * Illustrative Compose chrome screen — not wired into [com.example.gametemplate.MainActivity]
 * by default, since this template's [com.example.gametemplate.GameView] is set directly as the
 * content view (see `docs/adr/0002-rendering-approach.md`). Wire this in via a second Activity,
 * a Compose `NavHost`, or an `AndroidView`-hosted overlay once you have real menu flows —
 * see `.agent/rules/ui_compose.md` and `.agent/workflows/ui_compose.md`.
 *
 * Kept presentation-only: [onPlayClick] and [onSettingsClick] are callbacks the caller wires
 * to real navigation/state, per the "UI components are presentation-only" rule.
 */
@Composable
fun MainMenuScreen(
    onPlayClick: () -> Unit,
    onSettingsClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Surface(modifier = modifier.fillMaxSize(), color = MaterialTheme.colorScheme.background) {
        Column(
            modifier =
                Modifier
                    .fillMaxSize()
                    .padding(24.dp),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Button(
                onClick = onPlayClick,
                modifier = Modifier.semantics { contentDescription = "Start a new game" },
            ) {
                Text(text = stringResource(R.string.menu_play))
            }
            Button(
                onClick = onSettingsClick,
                modifier = Modifier.semantics { contentDescription = "Open settings" },
            ) {
                Text(text = stringResource(R.string.menu_settings))
            }
        }
    }
}

@Preview(showBackground = true)
@Composable
private fun MainMenuScreenPreview() {
    MainMenuScreen(onPlayClick = {}, onSettingsClick = {})
}
