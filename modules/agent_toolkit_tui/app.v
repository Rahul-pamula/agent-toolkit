module agent_toolkit_tui

// TUI — Dashboard + Loop Detail + Doctor screens.
// In-process core calls (no HTTP), offline-first per ADR-494.

import agent_toolkit_core
import os
import time

pub struct TuiOptions {
pub:
	workspace_path string
}

pub struct LoopInfo {
pub:
	name        string
	tier        string
	cadence     string
	last_status string
	runs_count  int
}

// ansi wraps text with ANSI code and resets.
pub fn ansi(s string, code string) string {
	return '\x1b[${code}m${s}\x1b[0m'
}

// color_for_tier maps tier to ANSI color code.
pub fn color_for_tier(tier string) string {
	return match tier {
		'L1' { '32' } // green
		'L2' { '33' } // yellow
		'L3' { '31' } // red
		else { '37' } // white
	}
}

// truncate shortens s to max_len with ellipsis if needed.
fn truncate(s string, max_len int) string {
	if s.len <= max_len {
		return s
	}
	if max_len <= 3 {
		return s[..max_len]
	}
	return s[..max_len - 3] + '...'
}

// pad_right truncates and pads s to exactly width, avoiding negative repeat.
fn pad_right(s string, width int) string {
	truncated := truncate(s, width)
	pad := width - truncated.len
	if pad <= 0 {
		return truncated
	}
	return truncated + ' '.repeat(pad)
}

// resolve_workspace finds the workspace root: override, env, then walk-up.
pub fn resolve_workspace(input string) string {
	if input.len > 0 && os.is_dir(input) {
		return input
	}
	for env in ['AGENT_TOOLKIT_WORKSPACE', 'HARNESS_DIR'] {
		val := os.getenv(env).trim_space()
		if val.len > 0 && os.is_dir(val) {
			return val
		}
	}
	mut cur := os.getwd()
	for {
		if os.is_dir(os.join_path(cur, 'loops')) || os.is_file(os.join_path(cur, 'AGENTS.md'))
			|| os.is_dir(os.join_path(cur, '.git')) || os.is_dir(os.join_path(cur, 'knowledge')) {
			return cur
		}
		parent := os.dir(cur)
		if parent == cur || parent.len == 0 {
			break
		}
		cur = parent
	}
	if input.len > 0 {
		return input
	}
	return os.getwd()
}

// list_loops scans loops/ for loop.yaml entries.
pub fn list_loops(workspace string) []LoopInfo {
	mut out := []LoopInfo{}
	dir := os.join_path(workspace, 'loops')
	if !os.is_dir(dir) {
		return out
	}
	for entry in os.ls(dir) or { []string{} } {
		loop_dir := os.join_path(dir, entry)
		yaml_path := os.join_path(loop_dir, 'loop.yaml')
		if !os.is_file(yaml_path) {
			continue
		}
		text := os.read_file(yaml_path) or { continue }
		mut tier := 'L1'
		mut cadence := '?'
		for line in text.split_into_lines() {
			t := line.trim_space()
			if t.starts_with('tier:') {
				tier = t.all_after('tier:').trim_space()
			} else if t.starts_with('cadence:') {
				cadence = t.all_after('cadence:').trim_space().trim('"')
			}
		}
		state_path := os.join_path(loop_dir, 'STATE.md')
		mut status := 'not_run'
		mut runs := 0
		if os.is_file(state_path) {
			runs = 1
			state_text := os.read_file(state_path) or { '' }
			for sl in state_text.split_into_lines() {
				if sl.trim_space().starts_with('last_run_status:') {
					status = sl.all_after('last_run_status:').trim_space()
					break
				}
			}
			// Try to count additional runs from STATE if it contains runs_count or history
			for sl in state_text.split_into_lines() {
				tt := sl.trim_space()
				if tt.starts_with('runs_count:') || tt.starts_with('run_count:') {
					val := tt.all_after(':').trim_space()
					if val.int() > runs {
						runs = val.int()
					}
				}
			}
		}
		out << LoopInfo{
			name:        entry
			tier:        tier
			cadence:     cadence
			last_status: status
			runs_count:  runs
		}
	}
	return out
}

// doctor_summary returns human-readable doctor output.
pub fn doctor_summary(workspace string) string {
	snap := agent_toolkit_core.run_doctor_readonly()
	return snap.message
}

// render_dashboard produces an ANSI-colored dashboard preview (also used for --json fallback tests).
pub fn render_dashboard(loops []LoopInfo, workspace string) string {
	ver := agent_toolkit_core.resolve_toolkit_version()
	now := time.utc().format_rfc3339()[..10]
	header := ansi('agent-toolkit TUI', '35') + ' — ${ver}  (${now})'
	mut lines := []string{}
	lines << '╭─────────────────────────────────────────────────────╮'
	lines << '│  ${header}'
	lines << '│  workspace: ${pad_right(workspace, 38)} │'
	lines << '├─────────────────────────────────────────────────────┤'
	lines << '│  Loops                                              │'
	lines << '│  ─────                                              │'
	if loops.len == 0 {
		lines << '│  (no loops found)                                 │'
	} else {
		for lp in loops {
			tier_colored := ansi(pad_right(lp.tier, 4), color_for_tier(lp.tier))
			name_disp := pad_right(lp.name, 18)
			cad_disp := pad_right(lp.cadence, 8)
			status_disp := pad_right(lp.last_status, 10)
			runs_disp := if lp.runs_count > 0 { 'x${lp.runs_count}' } else { '' }
			lines << '│  ${name_disp} ${tier_colored} ${cad_disp} ${status_disp} ${runs_disp}'
		}
	}
	lines << '│                                                     │'
	lines << '│  ${ansi("[1]dash [2]loops [3]skills [4]doctor [h]elp [q]uit", "90")} │'
	lines << '╰─────────────────────────────────────────────────────╯'
	return lines.join('\n')
}
