package org.kolonitsky.coursera.nlp;

import org.apache.commons.io.FileUtils;

import java.io.File;
import java.io.IOException;
import java.net.URISyntaxException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/**
 * @author Alex.Kolonitsky
 */
public class ReplaceRareWords {

    public static final int RARE_THRESHOLD = 5;
    public static final String RARE_WORD = "__RARE__";

    public final File taggedWordsFile;
    public String taggedWords;

    public ReplaceRareWords(File taggedWordsFile) {
        this.taggedWordsFile = taggedWordsFile;
    }

    public ReplaceRareWords load() throws IOException {
        taggedWords = FileUtils.readFileToString(taggedWordsFile);
        return this;
    }

    public ReplaceRareWords filter(List<WordCount> words) {
        for (WordCount entry : words) {
            if (entry.count <= RARE_THRESHOLD) {
                taggedWords = taggedWords.replace(entry.words[1] + " " + entry.words[0],
                                                       RARE_WORD + " " + entry.words[0]);
            }
        }

        return this;
    }

    public void save() throws IOException {
        FileUtils.writeStringToFile(taggedWordsFile, taggedWords);
    }

    public static void main(String[] args) throws IOException, URISyntaxException {
        DataManager data = new DataManager();
        data.load(getFile(args[0]));

        new ReplaceRareWords(getFile(args[1]))
                .load().filter(data.get(DataManager.Type.WORD_PROBABILIST)).save();
    }

    private static File getFile(String arg) throws URISyntaxException {
        return new File("D:\\Dropbox\\coursera-nlp\\nlp\\src\\main\\resources\\" + arg);
//        return new File(Thread.currentThread().getContextClassLoader().getResource(arg).toURI());
    }
}
