function comprobar
    set_color --bold blue
    echo "> COMPROBANDO PACMAN..."
    if type -q checkupdates
        checkupdates
    else
    set_color --bold red
        echo ">> ERROR. Quizá no exista el comando <<"
    end
    set_color --bold blue
    echo "> COMPROBANDO PARU..."
    if type -q paru
        paru -Qua
    else
    set_color --bold red
        echo ">> ERROR. Quizá no esté instalado <<"
    end
    set_color --bold blue
    echo "> COMPROBANDO YAY..."
    if type -q yay
        yay -Qua
    else
    set_color --bold red
        echo ">> ERROR. Quizá no esté instalado <<"
    end
    set_color --bold blue
    echo "> COMPROBANDO FLATPAK"
    if type -q flatpak
        flatpak remote-ls --updates
    else
    set_color --bold red
        echo ">> ERROR. Quizá no exista el comando <<"
    end
end