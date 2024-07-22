/**
 * @author: "laplace"
 * @date: 2024-07-16T21:38:10
 * @lastmod: 2024-07-23T01:50:19
 * @description:  
 * @filePath: /shu-course/Data-Struct/Algo/Problemsolving-Log/ProbSolving-Log.cpp
 * @lastEditor: Laplace825
 * @Copyright: Copyright (c) 2024 by Laplace825, All Rights Reserved.
 */
#include <vector>
#include <string>
#include <iostream>

void probSolvingLog()
{
    using std::cin, std::cout;
    using std::string;
    using std::vector;
    vector<char> hashTable(300);
    for (int i = 0; i < 26; i++)
    {
        hashTable.at('A' + i) = i + 1;
    }
    long long n; // n is the number of the test cases
    cin >> n;
    string str; // str is the string

    long long timeCount = 0;
    long long time = 0, ans = 0;
    for (auto i = 0; i < n; i++)
    {
        ans = 0;
        cin >> time;
        cin >> str;
        for (auto ch : str)
        {
            if (timeCount < time)
            {
                timeCount += hashTable.at(ch);
                ans++;
            }
            else
                break;
        }
        cout << ans << '\n';
    }
}

int main (){
    probSolvingLog();
    return 0;
}