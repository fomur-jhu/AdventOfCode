namespace AdventOfCode2022;

public static class Day01
{
    public static void P01()
    {
        var input = File.ReadAllText(@"InputFiles\D01P01.txt");
        var groups = input.Split("\n\n");
        var calories = groups.Select(g =>
            g.Split("\n", StringSplitOptions.RemoveEmptyEntries).Select(snackCals => Convert.ToInt32(snackCals.Trim()))
                .Sum());
        Console.WriteLine(calories.Max());
    }

    public static void P02()
    {
        var input = File.ReadAllText(@"InputFiles\D01P01.txt");
        var groups = input.Split("\n\n");
        var calories = groups.Select(g =>
            g.Split("\n", StringSplitOptions.RemoveEmptyEntries).Select(snackCals => Convert.ToInt32(snackCals.Trim()))
                .Sum()).OrderByDescending(i => i);
        Console.WriteLine(calories.Take(3).Sum());
    }
}