if status is-interactive
    type -q claude; and alias cc claude
    type -q codex; and alias cx codex

    if type -q starship
        starship init fish | source
    end
end
