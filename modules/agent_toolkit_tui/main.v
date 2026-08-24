module agent_toolkit_tui

import agent_toolkit_core
import os

// run_tui starts the interactive TUI with ANSI rendering and keyboard navigation.
pub fn run_tui(opts TuiOptions) int {
	ws := resolve_workspace(opts.workspace_path)
	mut loops := list_loops(ws)
	mut current := 'dashboard'
	mut selected := 0

	for {
		clear_screen()
		screen := render_screen(current, loops, ws, selected)
		println(screen)
		print('\n> command [1 dashboard, 2 loops, 3 skills, 4 doctor, j/k nav, r run, h help, q quit]: ')
		input := os.input('').trim_space().to_lower()
		if input in ['q', 'quit', 'exit'] {
			println(ansi('Bye!', '35'))
			break
		}
		if input in ['h', 'help', '?'] {
			current = 'help'
			continue
		}
		current, selected = handle_input(input, current, selected, loops, ws)
		// Refresh loops after any action that may have changed state
		if input in ['r', 'run', 'enter'] {
			loops = list_loops(ws)
		}
		// Clamp selection
		if loops.len > 0 {
			if selected < 0 {
				selected = 0
			}
			if selected >= loops.len {
				selected = loops.len - 1
			}
		} else {
			selected = 0
		}
	}
	return 0
}

// clear_screen clears terminal via ANSI escape.
fn clear_screen() {
	print('\x1b[2J\x1b[H')
}

// handle_input updates navigation state and executes actions.
fn handle_input(input string, current string, selected int, loops []LoopInfo, workspace string) (string, int) {
	mut cur := current
	mut sel := selected
	match input {
		'1', 'dashboard', 'd', 'home' {
			cur = 'dashboard'
		}
		'2', 'loops', 'l' {
			cur = 'loops'
		}
		'3', 'skills', 's' {
			cur = 'skills'
		}
		'4', 'doctor', 'doc' {
			cur = 'doctor'
		}
		'j', 'down', 'n' {
			if cur == 'loops' && loops.len > 0 {
				if sel < loops.len - 1 {
					sel++
				}
			}
		}
		'k', 'up', 'p' {
			if cur == 'loops' && loops.len > 0 {
				if sel > 0 {
					sel--
				}
			}
		}
		'r', 'run', 'enter' {
			if cur == 'loops' && loops.len > 0 && sel >= 0 && sel < loops.len {
				name := loops[sel].name
				println('')
				println(ansi('→ Running loop ${name} (no-llm, safe mode)...', '36'))
				report := agent_toolkit_core.run_loop(agent_toolkit_core.LoopOptions{
					subcommand:     'run'
					workspace_path: workspace
					name:           name
					no_llm:         true
				})
				println(report.message)
				if !report.ok {
					println(ansi('Run failed or skipped — check loop status.', '33'))
				} else {
					println(ansi('Done.', '32'))
				}
				print('Press enter to continue...')
				os.input('')
			} else if cur == 'loops' {
				println(ansi('(no loop selected)', '33'))
				print('Press enter to continue...')
				os.input('')
			} else {
				cur = 'loops'
			}
		}
		'' {
			// enter without command: if in loops, treat as detail/run hint
			if cur == 'loops' && loops.len > 0 {
				// no-op, stay
			}
		}
		else {
			// Unknown input: show hint and stay
			if input.len > 0 {
				println(ansi("Unknown: ${input} — press h for help, q to quit", '33'))
				print('Press enter to continue...')
				os.input('')
			}
		}
	}
	return cur, sel
}
