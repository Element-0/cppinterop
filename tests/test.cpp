#include <iostream>
#include <map>
#include <string>
#include <vector>

extern "C" {
void printstr(std::string str) { std::cout << str << std::endl; }
void printstrref(std::string &str) { std::cout << str << std::endl; }
void printstrconstref(std::string const &str) { std::cout << str << std::endl; }
void printmap(std::map<int, int> m) {
  for (auto [k, v] : m) {
    std::cout << k << " -> " << v << std::endl;
  }
}
void printstrmap(std::map<int, std::string> m) {
  for (auto [k, v] : m) {
    std::cout << k << " -> " << v << std::endl;
  }
}

std::string returnstr() { return "test"; }
std::string returnlongstr() {
  return "longtestlongtestlongtestlongtestlongtest";
}

std::vector<int> returnintvec() { return {1, 2, 3}; }

std::map<int, int> returnmap() { return {{0, 1}, {3, 2}, {2, 3}}; }
std::map<int, std::string> returnstrmap() { return {{0, "1"}, {3, "2"}, {2, "3"}}; }

void printintvec(std::vector<int> ints) {
  std::cout << "here" << std::endl;
  std::cout << ints.size() << std::endl;
  for (auto i : ints) {
    std::cout << i << " ";
  }
  std::cout << std::endl;
  std::cout << "dest" << std::endl;
}
void printintvecref(std::vector<int> &ints) {
  for (auto i : ints) {
    std::cout << i << " ";
  }
  std::cout << std::endl;
}

void printstrvec(std::vector<std::string> &strs) {
  for (auto i : strs) {
    std::cout << i << " ";
  }
  std::cout << std::endl;
}
}