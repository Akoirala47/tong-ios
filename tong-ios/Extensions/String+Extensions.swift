import Foundation

extension String {
    /// Calculate the Levenshtein distance between this string and another string
    /// - Parameter other: String to compare with
    /// - Returns: The edit distance (number of insertions, deletions, or substitutions required)
    func levenshteinDistance(to other: String) -> Int {
        let sCount = self.count
        let oCount = other.count
        
        guard sCount > 0 else { return oCount }
        guard oCount > 0 else { return sCount }
        
        // Create matrix
        var matrix = [[Int]](repeating: [Int](repeating: 0, count: oCount + 1), count: sCount + 1)
        
        // Initialize first row and column
        for i in 0...sCount {
            matrix[i][0] = i
        }
        
        for j in 0...oCount {
            matrix[0][j] = j
        }
        
        // Fill the matrix
        for i in 1...sCount {
            for j in 1...oCount {
                let selfIndex = self.index(self.startIndex, offsetBy: i-1)
                let otherIndex = other.index(other.startIndex, offsetBy: j-1)
                
                if self[selfIndex] == other[otherIndex] {
                    matrix[i][j] = matrix[i-1][j-1]  // No operation required
                } else {
                    // Minimum of delete, insert, or substitute
                    matrix[i][j] = Swift.min(
                        matrix[i-1][j] + 1,      // Deletion
                        matrix[i][j-1] + 1,      // Insertion
                        matrix[i-1][j-1] + 1     // Substitution
                    )
                }
            }
        }
        
        return matrix[sCount][oCount]
    }
} 