if status is-interactive
    alias cc claude
    alias cx codex

    if type -q starship
        starship init fish | source
    end
end
