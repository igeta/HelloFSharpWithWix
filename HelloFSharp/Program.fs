namespace HelloFSharp

module Program =
    [<EntryPoint>]
    let main _ = 
        printfn "Hello, F#!"
        printfn ""
        printf "Press Enter to end..."
        stdin.ReadLine() |> ignore
        0
