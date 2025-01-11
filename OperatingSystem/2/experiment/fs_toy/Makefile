clean:
	@echo "Cleaning up..."
	@cargo clean

debug:
	@echo "Building in debug mode..."
	@cargo build

release:
	@echo "Building in release mode..."
	@cargo build --release

run:
	@clear
	@echo "Running..."
	@cargo run --release

all: debug release

.Phony: all debug release clean run
