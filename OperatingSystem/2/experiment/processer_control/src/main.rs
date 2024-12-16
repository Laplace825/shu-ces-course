#![allow(unused)]
use crossterm::event::Event;
use pcb::{PriorityAlgo, RoundRobinAlgo, Scheduling};
use ratatui::{
    crossterm::event::{self, KeyCode, KeyEventKind},
    layout::{Constraint, Layout, Position, Rect},
    style::{self, Color, Style, Stylize},
    text::{Line, Span, Text},
    widgets::{
        self, Block, List, ListItem, Paragraph, Row, Scrollbar, ScrollbarState, Table, TableState,
    },
    DefaultTerminal, Frame,
};
use std::io;

fn main() -> std::io::Result<()> {
    let mut terminal = ratatui::init();
    terminal.clear()?;
    let mut app = App::default();
    app.run()?;
    ratatui::restore();
    Ok(())
}

#[derive(Debug, Default)]
struct App {
    mode: pcb::Algo,
}

impl App {
    fn run(&mut self) -> io::Result<()> {
        let mut terminal = ratatui::init();
        terminal.clear()?;
        let mut input_app = InputApp::default();
        let msgs = input_app.draw(
            "<0> to choose Priority, <1> to RoundRobin, <number> for time slice".to_string(),
            &mut terminal,
        )?;
        let mut msg_iter = msgs[0].split(" ");
        let msg = msg_iter.next().unwrap();
        let time_slice = msg_iter.next().unwrap().parse::<usize>().unwrap();
        terminal.clear()?;
        if msg.eq("0") {
            self.mode = pcb::Algo::PriorityAlgo;
        } else {
            self.mode = pcb::Algo::RoundRobinAlgo;
        }
        let mut input_app = InputApp::default();
        let msgs = input_app.draw("<Priority>, <CPU Require Time>".to_string(), &mut terminal)?;
        match self.mode {
            pcb::Algo::PriorityAlgo => {
                let mut app = ScheduleApp::<pcb::Control<PriorityAlgo>>::default();
                app.run(&msgs, &mut terminal, time_slice)?;
                ratatui::restore();
            }
            pcb::Algo::RoundRobinAlgo => {
                let mut app = ScheduleApp::<pcb::Control<RoundRobinAlgo>>::default();
                app.run(&msgs, &mut terminal, time_slice)?;
                ratatui::restore();
            }
        }
        Ok(())
    }
}

#[derive(Debug, Default)]
struct InputApp {
    input: String,
    character_index: usize,
    msgs: Vec<String>,
    exit: bool,
}

impl InputApp {
    fn draw(&mut self, title: String, terminal: &mut DefaultTerminal) -> io::Result<Vec<String>> {
        while !self.exit {
            terminal.draw(|frame| self.edit(&title, frame))?;
            if let Event::Key(key) = event::read().unwrap() {
                if key.kind == KeyEventKind::Press {
                    match key.code {
                        KeyCode::Char(c) => self.enter_char(c),
                        KeyCode::Backspace => self.delete_char(),
                        KeyCode::Enter => self.submit_message(),
                        KeyCode::Left => self.move_cursor_left(),
                        KeyCode::Right => self.move_cursor_right(),
                        _ => {
                            self.exit = true;
                        }
                    }
                }
            }
        }
        Ok(self.msgs.clone())
    }

    fn edit(&mut self, title: &str, frame: &mut Frame) {
        let vertical = Layout::vertical([
            Constraint::Length(1),
            Constraint::Length(3),
            Constraint::Min(1),
        ]);
        let [help_area, input_area, messages_area] = vertical.areas(frame.area());

        let (msg, style) = (
            vec![
                "Press ".into(),
                "Esc".bold(),
                " to stop editing, ".into(),
                "Enter".bold(),
                " to record the message".into(),
            ],
            Style::default(),
        );
        let text = Text::from(Line::from(msg)).patch_style(style);
        let help_message = Paragraph::new(text);
        frame.render_widget(help_message, help_area);

        let input = Paragraph::new(self.input.as_str())
            .style(Style::default().fg(Color::Yellow))
            .block(Block::bordered().title(title));
        frame.render_widget(input, input_area);

        frame.set_cursor_position(Position::new(
            // Draw the cursor at the current position in the input field.
            // This position is can be controlled via the left and right arrow key
            input_area.x + self.character_index as u16 + 1,
            // Move one line down, from the border to the input line
            input_area.y + 1,
        ));

        let messages: Vec<ListItem> = self
            .msgs
            .iter()
            .map(|m| {
                let content = Line::from(Span::raw(m));
                ListItem::new(content)
            })
            .collect();
        let messages = List::new(messages).block(Block::bordered().title("Messages"));
        frame.render_widget(messages, messages_area);
    }

    fn move_cursor_left(&mut self) {
        let cursor_moved_left = self.character_index.saturating_sub(1);
        self.character_index = self.clamp_cursor(cursor_moved_left);
    }

    fn move_cursor_right(&mut self) {
        let cursor_moved_right = self.character_index.saturating_add(1);
        self.character_index = self.clamp_cursor(cursor_moved_right);
    }

    fn enter_char(&mut self, new_char: char) {
        let index = self.byte_index();
        self.input.insert(index, new_char);
        self.move_cursor_right();
    }

    /// Returns the byte index based on the character position.
    ///
    /// Since each character in a string can be contain multiple bytes, it's necessary to calculate
    /// the byte index based on the index of the character.
    fn byte_index(&self) -> usize {
        self.input
            .char_indices()
            .map(|(i, _)| i)
            .nth(self.character_index)
            .unwrap_or(self.input.len())
    }

    fn delete_char(&mut self) {
        let is_not_cursor_leftmost = self.character_index != 0;
        if is_not_cursor_leftmost {
            // Method "remove" is not used on the saved text for deleting the selected char.
            // Reason: Using remove on String works on bytes instead of the chars.
            // Using remove would require special care because of char boundaries.

            let current_index = self.character_index;
            let from_left_to_current_index = current_index - 1;

            // Getting all characters before the selected character.
            let before_char_to_delete = self.input.chars().take(from_left_to_current_index);
            // Getting all characters after selected character.
            let after_char_to_delete = self.input.chars().skip(current_index);

            // Put all characters together except the selected one.
            // By leaving the selected one out, it is forgotten and therefore deleted.
            self.input = before_char_to_delete.chain(after_char_to_delete).collect();
            self.move_cursor_left();
        }
    }

    fn clamp_cursor(&self, new_cursor_pos: usize) -> usize {
        new_cursor_pos.clamp(0, self.input.chars().count())
    }

    fn reset_cursor(&mut self) {
        self.character_index = 0;
    }

    fn submit_message(&mut self) {
        self.msgs.push(self.input.clone());
        self.input.clear();
        self.reset_cursor();
    }
}

#[derive(Default, Debug)]
struct ScheduleApp<C>
where
    C: Scheduling,
{
    pcb_controller: C,
    exit: bool,
    tablestate: TableState,
    run_stack: u32,
    vertical_scroll_state: ScrollbarState,
    vertical_scroll: usize,
    time_slice: usize,
    run_result: Vec<(u32, u32)>, // [(idx, pid)]
}

impl<C: Scheduling> ScheduleApp<C> {
    fn run(
        &mut self,
        msgs: &[String],
        terminal: &mut DefaultTerminal,
        time_slice: usize,
    ) -> io::Result<()> {
        self.build_input(msgs);
        self.time_slice = time_slice;
        self.run_stack = *self
            .pcb_controller
            .build(self.time_slice as i32)
            .last()
            .unwrap();
        while !self.exit {
            terminal.clear()?;
            terminal.draw(|frame| self.draw(frame))?;
            if !self.pcb_controller.is_empty() {
                self.handle_input()?;
                continue;
            }
            self.handle_scroll()?;
            self.handle_exit()?;
        }
        Ok(())
    }

    fn build_input(&mut self, msgs: &[String]) {
        msgs.iter().for_each(|msg| {
            let mut iter = msg.split_whitespace();
            let priority = iter.next().unwrap().parse::<u32>().unwrap();
            let cpu_require_time = iter.next().unwrap().parse::<i32>().unwrap();
            self.push_pcb(pcb::PCB::new(priority, cpu_require_time));
        });
    }

    fn random_color(&self) -> style::Color {
        static mut INDEX: usize = 0;
        let colors = [style::Color::Gray, style::Color::White];

        colors[unsafe {
            INDEX += 1;
            INDEX %= colors.len();
            INDEX
        }]
    }

    fn push_pcb(&mut self, pcb: pcb::PCB) {
        self.pcb_controller.push(pcb);
    }

    fn push_pcbs(&mut self, pcbs: &[pcb::PCB]) {
        pcbs.iter().for_each(|pcb| self.push_pcb(*pcb));
    }

    fn draw(&mut self, frame: &mut Frame) {
        let rects = &Layout::vertical([
            Constraint::Min(2),
            Constraint::Min(2),
            Constraint::Length(3),
        ])
        .split(frame.area());
        self.render_table(frame, rects[0]);
        self.render_res(frame, rects[1]);
        self.render_footer(frame, rects[2]);
    }

    fn render_footer(&mut self, frame: &mut Frame, area: Rect) {
        let text = Paragraph::new(Line::from("Press 'Enter' to continue, 'Esc' to exit"))
            .style(style::Style::default().fg(style::Color::Yellow))
            .centered()
            .block(
                Block::bordered()
                    .border_type(widgets::BorderType::Double)
                    .border_style(Style::new().fg(style::Color::LightBlue)),
            );
        frame.render_widget(text, area);
    }

    fn render_res(&mut self, frame: &mut Frame, area: Rect) {
        let text = self
            .run_result
            .iter()
            .map(|(_, pid)| {
                Line::from(
                    format!("pid runned: {}", pid)
                        .bg(self.random_color())
                        .fg(Color::Black),
                )
            })
            .collect::<Vec<Line>>();

        frame.render_widget(
            Paragraph::new(text)
                .block(
                    Block::default()
                        .title("Run Result")
                        .borders(widgets::Borders::ALL)
                        .border_style(Style::new().fg(style::Color::LightBlue)),
                )
                .scroll((self.vertical_scroll as u16, 0)),
            area,
        );
        frame.render_stateful_widget(
            Scrollbar::new(widgets::ScrollbarOrientation::VerticalRight),
            area,
            &mut self.vertical_scroll_state,
        );
    }

    fn render_table(&mut self, frame: &mut Frame, area: Rect) {
        let header = [
            "PID",
            "Priority",
            "CPU Hold/time",
            "CPU Require/time",
            "State",
        ]
        .into_iter()
        .map(widgets::Cell::from)
        .collect::<Row>()
        .style(
            Style::default()
                .fg(style::Color::Red)
                .bg(style::Color::Gray),
        )
        .height(1);

        let rows = self
            .pcb_controller
            .get_pcbs()
            .iter()
            .enumerate()
            .map(|(i, pcb)| {
                let color = if i % 2 == 0 {
                    style::Color::White
                } else {
                    style::Color::Gray
                };
                let cells = [
                    pcb.pid.to_string(),
                    pcb.priority.to_string(),
                    pcb.cpu_hold_time.to_string(),
                    pcb.cpu_require_time.to_string(),
                    pcb.get_state(),
                ];
                cells
                    .iter()
                    .map(|content| widgets::Cell::from(Text::from(content.clone())))
                    .collect::<Row>()
                    .style(Style::default().bg(color).fg(Color::Black))
                    .height(1)
            });

        // rows's even row color is white, odd row color is gray

        let t = Table::new(
            rows,
            [
                Constraint::Length(20),
                Constraint::Length(20),
                Constraint::Length(20),
                Constraint::Length(20),
                Constraint::Length(20),
            ],
        )
        .header(header);
        frame.render_stateful_widget(t, area, &mut self.tablestate);
    }

    fn handle_exit(&mut self) -> io::Result<()> {
        match event::read()? {
            Event::Key(key_event) if key_event.kind == KeyEventKind::Press => {
                if key_event.code == KeyCode::Esc {
                    self.exit();
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_scroll(&mut self) -> io::Result<()> {
        match event::read()? {
            Event::Key(key_event) if key_event.kind == KeyEventKind::Press => {
                match key_event.code {
                    KeyCode::Char('j') | KeyCode::Down => {
                        self.vertical_scroll = self.vertical_scroll.saturating_add(1);
                        self.vertical_scroll_state =
                            self.vertical_scroll_state.position(self.vertical_scroll);
                    }
                    KeyCode::Char('k') | KeyCode::Up => {
                        self.vertical_scroll = self.vertical_scroll.saturating_sub(1);
                        self.vertical_scroll_state =
                            self.vertical_scroll_state.position(self.vertical_scroll);
                    }
                    _ => {}
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_input(&mut self) -> io::Result<()> {
        match event::read()? {
            Event::Key(key_event) if key_event.kind == KeyEventKind::Press => {
                match key_event.code {
                    KeyCode::Esc => self.exit(),
                    KeyCode::Char('j') | KeyCode::Down => {
                        self.vertical_scroll = self.vertical_scroll.saturating_add(1);
                        self.vertical_scroll_state =
                            self.vertical_scroll_state.position(self.vertical_scroll);
                    }
                    KeyCode::Char('k') | KeyCode::Up => {
                        self.vertical_scroll = self.vertical_scroll.saturating_sub(1);
                        self.vertical_scroll_state =
                            self.vertical_scroll_state.position(self.vertical_scroll);
                    }
                    KeyCode::Enter => self.continue_sched(),
                    _ => {}
                }
            }
            _ => {}
        }
        Ok(())
    }

    /// should call the pcbs Schedule method
    fn continue_sched(&mut self) {
        let (who_runned_idx, who_runned_pid) = self.pcb_controller.step();
        self.run_result
            .push((who_runned_idx as u32, who_runned_pid as u32));
    }

    fn exit(&mut self) {
        self.exit = true;
    }
}
